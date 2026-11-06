import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/core/network/connection_error.dart';
import 'package:lumen/data/m3u/m3u_parser.dart';

Uint8List u8(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  test('basic attributes, name after the attribute block', () {
    final p = parseM3uText(
      '#EXTM3U url-tvg="http://epg.invalid/a.xml.gz,http://b.invalid"\n'
      '#EXTINF:-1 tvg-id="news.uk" tvg-name="News HD" '
      'tvg-logo="http://img.invalid/n.png" tvg-chno="101" '
      'group-title="News, Weather & More",News HD\n'
      'http://h.invalid/live/u/p/1.ts\n',
    );
    expect(p.epgUrl, 'http://epg.invalid/a.xml.gz');
    final e = p.entries.single;
    expect(e.name, 'News HD');
    expect(e.group, 'News, Weather & More');
    expect(e.tvgId, 'news.uk');
    expect(e.logo, 'http://img.invalid/n.png');
    expect(e.channelNumber, 101);
    expect(e.kind, M3uKind.live);
  });

  test('commas inside quoted attributes and inside the name', () {
    final p = parseM3uText(
      '#EXTM3U\n'
      '#EXTINF:-1 tvg-name="A, B, C" group-title="x,y",Sport, Live, HD\n'
      'http://h.invalid/1\n',
    );
    expect(p.entries.single.tvgName, 'A, B, C');
    expect(p.entries.single.group, 'x,y');
    expect(p.entries.single.name, 'Sport, Live, HD');
  });

  test('EXTVLCOPT, EXTHTTP, KODIPROP and pipe headers', () {
    final p = parseM3uText(
      '#EXTM3U\n'
      '#EXTINF:-1,One\n'
      '#EXTVLCOPT:http-user-agent=Mozilla/5.0 (X11)\n'
      '#EXTVLCOPT:http-referrer=http://ref.invalid/\n'
      'http://h.invalid/1\n'
      '#EXTINF:-1,Two\n'
      '#EXTHTTP:{"User-Agent":"Custom/1","referer":"http://r2.invalid"}\n'
      'http://h.invalid/2\n'
      '#EXTINF:-1,Three\n'
      '#KODIPROP:inputstream.adaptive.stream_headers=User-Agent=Kodi%2F20&Referer=http://k.invalid\n'
      'http://h.invalid/3\n'
      '#EXTINF:-1,Four\n'
      'http://h.invalid/4|User-Agent=Pipe/1&Referer=http://p.invalid\n',
    );
    final h = p.entries.map((e) => e.headers).toList();
    expect(h[0], {
      'User-Agent': 'Mozilla/5.0 (X11)',
      'Referer': 'http://ref.invalid/',
    });
    expect(h[1], {'User-Agent': 'Custom/1', 'Referer': 'http://r2.invalid'});
    expect(h[2], {'User-Agent': 'Kodi/20', 'Referer': 'http://k.invalid'});
    expect(h[3], {'User-Agent': 'Pipe/1', 'Referer': 'http://p.invalid'});
    expect(p.entries[3].url, 'http://h.invalid/4');
  });

  test('options before #EXTINF still apply', () {
    final p = parseM3uText(
      '#EXTM3U\n#EXTVLCOPT:http-user-agent=Early/1\n#EXTINF:-1,X\nhttp://h/1\n',
    );
    expect(p.entries.single.headers['User-Agent'], 'Early/1');
  });

  test('CRLF, blank lines, duplicates and EXTGRP', () {
    final p = parseM3uText(
      '#EXTM3U\r\n\r\n#EXTINF:-1,A\r\n#EXTGRP:Films\r\nhttp://h/movie/u/p/1.mp4\r\n'
      '\r\n#EXTINF:-1,A\r\nhttp://h/movie/u/p/1.mp4\r\n'
      '#EXTINF:-1,S1E1\r\nhttp://h/series/u/p/5.mkv\r\n',
    );
    expect(p.entries, hasLength(3));
    expect(p.entries[0].group, 'Films');
    expect(p.entries[0].kind, M3uKind.movie);
    expect(p.entries[2].kind, M3uKind.series);
  });

  test('UTF-8 BOM', () {
    final p = parseM3u(
      Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('#EXTM3U\n#EXTINF:-1,Café\nhttp://h/1\n'),
      ]),
    );
    expect(p.entries.single.name, 'Café');
    expect(p.encoding, 'utf-8-bom');
  });

  test('Windows-1252 fallback', () {
    // "Café – Téle" in cp1252: é=0xE9, en dash=0x96.
    final bytes = Uint8List.fromList([
      ...ascii.encode('#EXTM3U\n#EXTINF:-1,Caf'),
      0xE9,
      ...ascii.encode(' '),
      0x96,
      ...ascii.encode(' T'),
      0xE9,
      ...ascii.encode('le\nhttp://h/1\n'),
    ]);
    final p = parseM3u(bytes);
    expect(p.encoding, 'windows-1252');
    expect(p.entries.single.name, 'Café – Téle');
  });

  test('missing name falls back to tvg-name, then URL', () {
    final p = parseM3uText(
      '#EXTM3U\n#EXTINF:-1 tvg-name="From Tvg",\nhttp://h/1\n'
      '#EXTINF:-1,\nhttp://h/path/Channel_9.m3u8\nhttp://h/bare.ts\n',
    );
    expect(p.entries.map((e) => e.name), ['From Tvg', 'Channel_9', 'bare']);
  });

  test('catchup attributes', () {
    final e = parseM3uText(
      '#EXTM3U\n#EXTINF:-1 catchup="shift" catchup-days="7" '
      'catchup-source="?utc={utc}",X\nhttp://h/1\n',
    ).entries.single;
    expect(e.catchup, 'shift');
    expect(e.catchupDays, 7);
    expect(e.catchupSource, '?utc={utc}');
  });

  test('not a playlist', () {
    for (final s in ['hello world', '<html></html>', '{"a":1}', '']) {
      expect(
        () => parseM3uText(s),
        throwsA(
          isA<ConnectionError>().having(
            (e) => e.kind,
            'kind',
            ConnectionErrorKind.m3uInvalid,
          ),
        ),
        reason: s,
      );
    }
  });

  test('50 MB playlist parses in an isolate', () async {
    final b = StringBuffer('#EXTM3U\r\n');
    var i = 0;
    while (b.length < 50 * 1024 * 1024) {
      b
        ..write('#EXTINF:-1 tvg-id="c$i" tvg-name="Channel, $i" ')
        ..write(
          'tvg-logo="http://img.invalid/$i.png" group-title="G${i % 50}",',
        )
        ..write('Channel $i\r\n')
        ..write('#EXTVLCOPT:http-user-agent=UA/$i\r\n')
        ..write('http://h.invalid/live/u/p/$i.ts\r\n');
      i++;
    }
    final bytes = Uint8List.fromList(utf8.encode(b.toString()));
    expect(bytes.length, greaterThan(50 * 1024 * 1024));

    // The UI isolate must keep ticking while parsing happens elsewhere.
    var ticks = 0;
    var maxGap = Duration.zero;
    var last = DateTime.now();
    final sw = Stopwatch()..start();
    final timer = Stream<void>.periodic(const Duration(milliseconds: 16))
        .listen((_) {
          final now = DateTime.now();
          final gap = now.difference(last);
          if (gap > maxGap) maxGap = gap;
          last = now;
          ticks++;
        });
    final p = await parseM3uInIsolate(bytes);
    await timer.cancel();
    sw.stop();

    expect(p.entries.length, i);
    expect(p.entries.last.headers['User-Agent'], 'UA/${i - 1}');
    expect(p.entries[5].tvgName, 'Channel, 5');
    expect(ticks, greaterThan(0));
    // Generous bound: copying the result back is the only main-isolate work.
    expect(
      maxGap,
      lessThan(const Duration(milliseconds: 1500)),
      reason: 'UI isolate stalled for $maxGap',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
