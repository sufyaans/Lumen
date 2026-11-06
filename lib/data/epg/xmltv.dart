/// XMLTV guide import (brief section 6): event-based streaming parse,
/// only channels in the user's lineup, only a window from 2 h ago to 48 h
/// ahead, stored as compact rows. Runs inside the sync isolate.
library;

import 'dart:convert';
import 'dart:io' show GZipCodec;

import 'package:drift/drift.dart';
import 'package:xml/xml_events.dart';

import '../db/app_database.dart';

/// Parses XMLTV times like `20240309070000 +0100` (offset optional, UTC
/// assumed when missing). Returns UTC, or null when unreadable.
DateTime? parseXmltvTime(String raw) {
  final m = RegExp(
    r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})?\s*([+-]\d{2}:?\d{2})?',
  ).firstMatch(raw.trim());
  if (m == null) return null;
  final t = DateTime.utc(
    int.parse(m[1]!),
    int.parse(m[2]!),
    int.parse(m[3]!),
    int.parse(m[4]!),
    int.parse(m[5]!),
    int.parse(m[6] ?? '0'),
  );
  final off = m[7]?.replaceAll(':', '');
  if (off == null) return t;
  final sign = off.startsWith('-') ? -1 : 1;
  final minutes =
      int.parse(off.substring(1, 3)) * 60 + int.parse(off.substring(3, 5));
  return t.subtract(Duration(minutes: sign * minutes));
}

/// Gunzips when the bytes start with the gzip magic number.
Uint8List maybeGunzip(Uint8List b) =>
    b.length > 2 && b[0] == 0x1f && b[1] == 0x8b
    ? Uint8List.fromList(GZipCodec().decode(b))
    : b;

class XmltvProgramme {
  const XmltvProgramme(
    this.channel,
    this.start,
    this.stop,
    this.title,
    this.description,
  );
  final String channel;
  final DateTime start;
  final DateTime stop;
  final String title;
  final String? description;
}

/// Streams programmes out of XMLTV text, filtered to [lineup] (compared
/// case-insensitively) and the [from]..[to] window.
Iterable<XmltvProgramme> parseXmltv(
  String xml, {
  required Set<String> lineup,
  required DateTime from,
  required DateTime to,
}) sync* {
  final wanted = {for (final id in lineup) id.toLowerCase()};
  String? channel;
  DateTime? start;
  DateTime? stop;
  String? field;
  StringBuffer? title;
  StringBuffer? desc;
  var keep = false;

  for (final e in parseEvents(xml)) {
    if (e is XmlStartElementEvent) {
      if (e.name == 'programme') {
        String? attr(String n) {
          for (final a in e.attributes) {
            if (a.name == n) return a.value;
          }
          return null;
        }

        channel = attr('channel');
        start = parseXmltvTime(attr('start') ?? '');
        stop = parseXmltvTime(attr('stop') ?? '');
        keep =
            channel != null &&
            start != null &&
            stop != null &&
            stop.isAfter(start) &&
            wanted.contains(channel.toLowerCase()) &&
            stop.isAfter(from) &&
            start.isBefore(to);
        title = StringBuffer();
        desc = StringBuffer();
        if (e.isSelfClosing) keep = false;
      } else if (keep && (e.name == 'title' || e.name == 'desc')) {
        // Only the first title/desc (often one per language).
        final target = e.name == 'title' ? title : desc;
        field = (target != null && target.isEmpty) ? e.name : null;
      }
    } else if ((e is XmlTextEvent || e is XmlCDATAEvent) &&
        keep &&
        field != null) {
      final v = e is XmlTextEvent ? e.value : (e as XmlCDATAEvent).value;
      (field == 'title' ? title : desc)!.write(v);
    } else if (e is XmlEndElementEvent) {
      if (e.name == 'title' || e.name == 'desc') {
        field = null;
      } else if (e.name == 'programme') {
        if (keep) {
          final t = title.toString().trim();
          final d = desc.toString().trim();
          yield XmltvProgramme(
            channel!,
            start!,
            stop!,
            t.isEmpty ? 'No title' : t,
            d.isEmpty ? null : d,
          );
        }
        keep = false;
        field = null;
      }
    }
  }
}

/// Replaces the stored guide for [providerId] with programmes from
/// [bytes] (`.xml` or `.xml.gz`). Returns the number of programmes kept.
Future<int> importXmltv(
  AppDatabase db, {
  required String providerId,
  required Uint8List bytes,
  required DateTime now,
}) async {
  final lineupRows =
      await (db.selectOnly(db.channels)
            ..addColumns([db.channels.epgId])
            ..where(
              db.channels.providerId.equals(providerId) &
                  db.channels.epgId.isNotNull(),
            ))
          .get();
  final lineup = {for (final r in lineupRows) r.read(db.channels.epgId)!};
  if (lineup.isEmpty) return 0;

  final text = utf8.decode(maybeGunzip(bytes), allowMalformed: true);
  final from = now.subtract(const Duration(hours: 2));
  final to = now.add(const Duration(hours: 48));

  // Keep the original channel id spelling from the lineup.
  final canonical = {for (final id in lineup) id.toLowerCase(): id};
  var count = 0;
  await db.transaction(() async {
    await (db.delete(
      db.epgPrograms,
    )..where((t) => t.providerId.equals(providerId))).go();
    var batch = <EpgProgramsCompanion>[];
    Future<void> flush() async {
      if (batch.isEmpty) return;
      final rows = batch;
      batch = [];
      await db.batch((b) => b.insertAll(db.epgPrograms, rows));
    }

    for (final p in parseXmltv(text, lineup: lineup, from: from, to: to)) {
      batch.add(
        EpgProgramsCompanion.insert(
          providerId: providerId,
          channelEpgId: canonical[p.channel.toLowerCase()] ?? p.channel,
          start: p.start,
          stop: p.stop,
          title: p.title,
          description: Value(p.description),
        ),
      );
      count++;
      if (batch.length >= 2000) await flush();
    }
    await flush();
  });
  return count;
}
