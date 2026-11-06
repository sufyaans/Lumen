import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../secure/credential_store.dart';
import '../xtream/connection_doctor.dart';

/// Saved providers. Secrets go to [CredentialStore], everything else to
/// the database (brief 4).
class ProviderRegistry {
  ProviderRegistry(this.db, this.store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final CredentialStore store;
  final DateTime Function() _clock;
  static final _rnd = Random.secure();

  String _newId() =>
      '${_clock().microsecondsSinceEpoch.toRadixString(36)}'
      '${_rnd.nextInt(1 << 32).toRadixString(36)}';

  Stream<List<ProviderRow>> watchAll() =>
      (db.select(db.providers)..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
          .watch();

  Future<List<ProviderRow>> all() =>
      (db.select(db.providers)..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
          .get();

  Future<ProviderRow?> byId(String id) => (db.select(
    db.providers,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Saves a provider after a successful sign-in probe.
  Future<String> addXtream({
    required ProbeSuccess probe,
    String? name,
    bool allowUntrustedCert = false,
  }) async {
    final id = _newId();
    final e = probe.profile.endpoint;
    await db
        .into(db.providers)
        .insert(
          ProvidersCompanion.insert(
            id: id,
            kind: 'xtream',
            name: (name == null || name.trim().isEmpty) ? e.host : name.trim(),
            displayHost: Value(e.displayHost),
            username: Value(probe.username),
            endpointJson: Value(jsonEncode(e.toJson())),
            userAgentId: Value(probe.profile.userAgent.id),
            allowUntrustedCert: Value(allowUntrustedCert),
            userInfoJson: Value(jsonEncode(probe.account.user.toJson())),
            serverInfoJson: Value(
              probe.account.server == null
                  ? null
                  : jsonEncode(probe.account.server!.toJson()),
            ),
            createdAt: _clock(),
          ),
        );
    await store.writePassword(id, probe.password);
    return id;
  }

  /// Saves an M3U link. The full URL is a secret (it may carry credentials).
  Future<String> addM3uUrl({
    required Uri url,
    String? name,
    String? epgUrl,
    bool allowUntrustedCert = false,
  }) async {
    final id = _newId();
    await db
        .into(db.providers)
        .insert(
          ProvidersCompanion.insert(
            id: id,
            kind: 'm3u_url',
            name: (name == null || name.trim().isEmpty)
                ? url.host
                : name.trim(),
            displayHost: Value(
              url.hasPort ? '${url.host}:${url.port}' : url.host,
            ),
            epgUrl: Value(
              epgUrl?.trim().isEmpty ?? true ? null : epgUrl!.trim(),
            ),
            allowUntrustedCert: Value(allowUntrustedCert),
            createdAt: _clock(),
          ),
        );
    await store.writeSecretUrl(id, url.toString());
    return id;
  }

  Future<String> addM3uFile({required String fileName, String? name}) async {
    final id = _newId();
    await db
        .into(db.providers)
        .insert(
          ProvidersCompanion.insert(
            id: id,
            kind: 'm3u_file',
            name: (name == null || name.trim().isEmpty)
                ? fileName.replaceAll(RegExp(r'\.[^.]+$'), '')
                : name.trim(),
            fileName: Value(fileName),
            createdAt: _clock(),
          ),
        );
    return id;
  }

  /// "Enter your password again" after secure storage lost it (brief 5.9).
  Future<bool> updatePassword(String id, String password) =>
      store.writePassword(id, password);

  Future<void> setAllowUntrustedCert(String id, bool allow) =>
      (db.update(db.providers)..where((t) => t.id.equals(id))).write(
        ProvidersCompanion(allowUntrustedCert: Value(allow)),
      );

  /// Removes a provider with its catalogue, guide, search rows, user data
  /// and secrets.
  Future<void> remove(String id) async {
    await db.transaction(() async {
      for (final t in <TableInfo<Table, Object?>>[
        db.categories,
        db.channels,
        db.movies,
        db.seriesTable,
        db.episodes,
        db.epgPrograms,
        db.favourites,
        db.myList,
        db.progress,
        db.recents,
      ]) {
        await db.customStatement(
          'DELETE FROM ${t.actualTableName} WHERE provider_id = ?',
          [id],
        );
      }
      await db.customStatement(
        'DELETE FROM search_index WHERE provider_id = ?',
        [id],
      );
      await (db.delete(db.providers)..where((t) => t.id.equals(id))).go();
    });
    await store.deleteAll(id);
  }
}
