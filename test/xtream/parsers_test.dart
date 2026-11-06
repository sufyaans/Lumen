import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/core/utils/text_clean.dart';
import 'package:lumen/data/xtream/server_endpoint.dart';
import 'package:lumen/data/xtream/stream_urls.dart';
import 'package:lumen/data/xtream/tolerant_json.dart';
import 'package:lumen/data/xtream/xtream_models.dart';
import 'package:lumen/data/xtream/xtream_parsers.dart';

Uint8List b(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  group('decodeProviderBody', () {
    test('plain JSON', () {
      expect((decodeProviderBody(b('{"a":1}')) as JsonBody).value, {'a': 1});
    });
    test('UTF-8 BOM and leading whitespace', () {
      final r = decodeProviderBody(b('﻿ \n\t{"a":1}'));
      expect((r as JsonBody).value, {'a': 1});
    });
    test('PHP warning before JSON', () {
      final r = decodeProviderBody(
        b(
          '<br />\n<b>Warning</b>: foo() in /var/www/x.php on line 3<br />\n'
          '{"user_info":{"auth":1}}',
        ),
      );
      expect(r, isA<JsonBody>());
      expect((r as JsonBody).hadJunkPrefix, isTrue);
    });
    test('text junk before a list', () {
      final r = decodeProviderBody(b('Notice: x\n[{"stream_id":1}]'));
      expect((r as JsonBody).value, [
        {'stream_id': 1},
      ]);
    });
    test('HTML page', () {
      expect(
        decodeProviderBody(b('<!DOCTYPE html><html><body>Hi</body></html>')),
        isA<HtmlBody>(),
      );
    });
    test('Cloudflare challenge is flagged', () {
      final r = decodeProviderBody(
        b('<html><title>Just a moment...</title>cf-ray</html>'),
      );
      expect((r as HtmlBody).cloudflare, isTrue);
    });
    test('empty and garbage', () {
      expect(decodeProviderBody(b('   ')), isA<EmptyBody>());
      expect(decodeProviderBody(b('not json at all')), isA<MalformedBody>());
    });
    test('false and null are valid JSON', () {
      expect((decodeProviderBody(b('false')) as JsonBody).value, false);
      expect((decodeProviderBody(b('null')) as JsonBody).value, isNull);
    });
  });

  group('coercion', () {
    test('asInt', () {
      expect(asInt(5), 5);
      expect(asInt('5'), 5);
      expect(asInt(' 7 '), 7);
      expect(asInt('3.0'), 3);
      expect(asInt(2.9), 2);
      expect(asInt(''), isNull);
      expect(asInt(false), 0);
      expect(asInt([]), isNull);
      expect(asInt('abc'), isNull);
    });
    test('asString treats false/[]/{}/"" as missing', () {
      expect(asString(false), isNull);
      expect(asString(<Object>[]), isNull);
      expect(asString(<String, Object>{}), isNull);
      expect(asString('  '), isNull);
      expect(asString(12), '12');
    });
    test('asBool', () {
      for (final t in [1, '1', true, 'true', 'Yes']) {
        expect(asBool(t), isTrue, reason: '$t');
      }
      for (final f in [0, '0', false, 'false', '', null, <Object>[]]) {
        expect(asBool(f), isFalse, reason: '$f');
      }
      expect(asBoolOrNull(null), isNull);
    });
    test('asList accepts false, null and index-keyed maps', () {
      expect(asList(false), isEmpty);
      expect(asList(null), isEmpty);
      expect(asList({'0': 'a', '1': 'b'}), ['a', 'b']);
    });
    test('asUnixTime: seconds, ms, strings, zero', () {
      final s = asUnixTime(1700000000)!;
      expect(s.isUtc, isTrue);
      expect(asUnixTime('1700000000'), s);
      expect(asUnixTime(1700000000000), s);
      expect(asUnixTime('1700000000000'), s);
      expect(asUnixTime(0), isNull);
      expect(asUnixTime(''), isNull);
      expect(asUnixTime(null), isNull);
    });
    test('asName decodes entities, collapses space, caps length', () {
      expect(asName('Tom &amp; Jerry &#39;HD&#39;'), "Tom & Jerry 'HD'");
      expect(asName('  a \n  b '), 'a b');
      expect(asName('x' * 500)!.runes.length, 201);
      expect(asName('📺 Émoji'), '📺 Émoji');
    });
    test('asImageUrl rejects empty and invalid', () {
      expect(asImageUrl(''), isNull);
      expect(asImageUrl(false), isNull);
      expect(asImageUrl('not a url'), isNull);
      expect(asImageUrl('/relative.png'), isNull);
      expect(asImageUrl('ftp://x/y.png'), isNull);
      expect(asImageUrl('http://x.example/a b.png'), contains('%20'));
    });
    test('decodeMaybeBase64', () {
      expect(
        decodeMaybeBase64(base64.encode(utf8.encode('Évening news'))),
        'Évening news',
      );
      expect(decodeMaybeBase64('Plain title!'), 'Plain title!');
      expect(decodeMaybeBase64(null), '');
    });
  });

  group('UserInfo', () {
    test('string numbers, auth "1", string exp_date', () {
      final u = UserInfo.parse({
        'auth': '1',
        'status': 'active',
        'exp_date': '1893456000',
        'max_connections': '2',
        'active_cons': '1',
        'is_trial': '0',
        'allowed_output_formats': ['M3U8', 'ts'],
      });
      expect(u.auth, isTrue);
      expect(u.status, AccountStatus.active);
      expect(u.expiresAt, DateTime.utc(2030));
      expect(u.maxConnections, 2);
      expect(u.activeConnections, 1);
      expect(u.allowedOutputFormats, ['m3u8', 'ts']);
      expect(u.atConnectionLimit, isFalse);
    });
    test('null / empty / 0 exp_date means no expiry', () {
      for (final v in [null, '', 0, '0', 'null']) {
        expect(UserInfo.parse({'exp_date': v}).expiresAt, isNull, reason: '$v');
      }
      expect(expiryLabel(null), 'No expiry');
    });
    test('status is case-insensitive', () {
      expect(UserInfo.parse({'status': 'BANNED'}).status, AccountStatus.banned);
      expect(
        UserInfo.parse({'status': 'Disabled'}).status,
        AccountStatus.disabled,
      );
      expect(UserInfo.parse({'status': 'Trial'}).isTrial, isTrue);
    });
    test('auth variants', () {
      expect(UserInfo.parse({'auth': 0}).auth, isFalse);
      expect(UserInfo.parse({'auth': false}).auth, isFalse);
      expect(UserInfo.parse({'auth': '0'}).auth, isFalse);
      expect(UserInfo.parse({'auth': true}).auth, isTrue);
      expect(UserInfo.parse({}).auth, isNull);
    });
    test('AccountInfo.parse of {} and [] is null', () {
      expect(AccountInfo.parse(<String, Object>{}), isNull);
      expect(AccountInfo.parse(<Object>[]), isNull);
      expect(AccountInfo.parse({'user_info': <Object>[]}), isNull);
    });
    test('server clock offset', () {
      final s = ServerInfo.parse({'timestamp_now': 1700000100});
      final off = s.clockOffset(
        deviceNow: DateTime.fromMillisecondsSinceEpoch(
          1700000000000,
          isUtc: true,
        ),
      );
      expect(off, const Duration(seconds: 100));
    });
  });

  group('lists survive junk', () {
    test('live streams', () {
      final list = parseLiveStreams([
        {'stream_id': '1', 'name': 'One', 'num': '1', 'category_id': 5},
        {'stream_id': 1, 'name': 'Duplicate'},
        {'stream_id': 2, 'name': '', 'num': 2, 'stream_icon': false},
        {'name': 'no id'},
        {'stream_id': 'x'},
        'not a map',
        null,
        {
          'stream_id': 3,
          'name': 'Émoji 📺 &amp; Co',
          'tv_archive': '1',
          'tv_archive_duration': '7',
          'category_ids': [9, 10],
          'epg_channel_id': null,
          'added': false,
        },
      ]);
      expect(list.map((e) => e.streamId), [1, 2, 3]);
      expect(list[0].name, 'One');
      expect(list[0].categoryId, '5');
      expect(list[1].name, 'Channel 2');
      expect(list[1].icon, isNull);
      expect(list[2].name, 'Émoji 📺 & Co');
      expect(list[2].tvArchive, isTrue);
      expect(list[2].tvArchiveDays, 7);
      expect(list[2].categoryIds, ['9', '10']);
    });
    test('false, null, {} and "" for an empty list', () {
      for (final v in [false, null, <String, Object>{}, '']) {
        expect(parseLiveStreams(v), isEmpty);
        expect(parseVodStreams(v), isEmpty);
        expect(parseSeriesList(v), isEmpty);
        expect(parseCategories(v), isEmpty);
      }
    });
    test('vod defaults and year', () {
      final v = parseVodStreams([
        {'stream_id': 7, 'name': 'Film (2019)', 'container_extension': ''},
        {'stream_id': 8, 'name': 'X', 'container_extension': '.MKV'},
      ]);
      expect(v[0].containerExtension, 'mp4');
      expect(v[0].year, 2019);
      expect(v[1].containerExtension, 'mkv');
    });
    test('categories dedupe and default name', () {
      final c = parseCategories([
        {'category_id': 1, 'category_name': 'News'},
        {'category_id': '1', 'category_name': 'Dup'},
        {'category_id': 2, 'category_name': ''},
      ]);
      expect(c.map((e) => e.name), ['News', 'Other']);
    });
  });

  group('series info', () {
    final ep = {
      'id': '11',
      'episode_num': '2',
      'title': 'Two',
      'container_extension': 'mkv',
    };
    test('episodes as map keyed by season', () {
      final s = parseSeriesInfo({
        'info': {'name': 'S'},
        'episodes': {
          '2': [ep],
          '1': [
            {'id': 10, 'episode_num': 1},
          ],
        },
      });
      expect(s.episodesBySeason.keys, [1, 2]);
      expect(s.episodesBySeason[1]!.single.containerExtension, 'mp4');
      expect(s.episodesBySeason[1]!.single.title, 'Episode 1');
      expect(s.episodesBySeason[2]!.single.id, '11');
    });
    test('episodes as a list (one season)', () {
      final s = parseSeriesInfo({
        'episodes': [
          ep,
          {'id': 12},
        ],
      });
      expect(s.episodesBySeason.keys, [1]);
      expect(s.episodesBySeason[1]!.map((e) => e.episodeNum), [2, 2]);
    });
    test('episodes missing, false or garbage', () {
      for (final v in [null, false, 'x', <Object>[]]) {
        expect(parseSeriesInfo({'episodes': v}).episodesBySeason, isEmpty);
      }
    });
  });

  test('short EPG uses timestamps and base64', () {
    final e = parseShortEpg({
      'epg_listings': [
        {
          'title': base64.encode(utf8.encode('Later')),
          'start': '2020-01-01 23:00:00',
          'start_timestamp': '1700003600',
          'stop_timestamp': 1700007200,
        },
        {
          'title': base64.encode(utf8.encode('First')),
          'start_timestamp': 1700000000,
          'stop_timestamp': 1700003600,
        },
        {'title': 'bad', 'start_timestamp': 5, 'stop_timestamp': 1},
      ],
    });
    expect(e.map((x) => x.title), ['First', 'Later']);
    expect(e.first.start, DateTime.utc(2023, 11, 14, 22, 13, 20));
  });

  group('stream URLs', () {
    const ep = ServerEndpoint(scheme: 'http', host: 'h.example', port: 8080);
    const pw = 'p@ss:w/rd?&#%+ é';
    const u = XtreamUrls(ep, 'us er', pw);

    test('credentials are encoded path segments that decode back', () {
      final live = u.live(42, ext: 'm3u8');
      expect(live.pathSegments, ['live', 'us er', pw, '42.m3u8']);
      expect(live.toString(), startsWith('http://h.example:8080/live/'));
      expect(live.toString(), isNot(contains('w/rd')));
      expect(Uri.parse(live.toString()).pathSegments[2], pw);
    });
    test('movie, episode, short live form', () {
      expect(u.movie(7, 'MKV').pathSegments.last, '7.mkv');
      expect(u.movie(7, '').pathSegments.last, '7.mp4');
      expect(u.episode('9001', 'mp4').pathSegments.first, 'series');
      expect(u.liveShort(42).pathSegments, ['us er', pw, '42']);
    });
    test('timeshift format', () {
      final t = u.timeshift(
        42,
        DateTime(2024, 3, 9, 7, 5),
        const Duration(minutes: 90),
      );
      expect(t.pathSegments, [
        'timeshift',
        'us er',
        pw,
        '90',
        '2024-03-09:07-05',
        '42.ts',
      ]);
    });
    test('base path is kept', () {
      const e2 = ServerEndpoint(
        scheme: 'https',
        host: 'h.example',
        basePath: '/x/y',
      );
      expect(
        const XtreamUrls(e2, 'a', 'b').live(1).toString(),
        'https://h.example/x/y/live/a/b/1.ts',
      );
    });
    test('live extension order', () {
      expect(
        liveExtensionOrder(
          setting: LiveFormatSetting.auto,
          allowedFormats: ['m3u8', 'ts'],
        ),
        ['m3u8', 'ts'],
      );
      expect(
        liveExtensionOrder(
          setting: LiveFormatSetting.auto,
          allowedFormats: ['ts'],
        ),
        ['ts', 'm3u8'],
      );
      expect(
        liveExtensionOrder(
          setting: LiveFormatSetting.auto,
          allowedFormats: ['m3u8', 'ts'],
          lastWorked: 'ts',
        ),
        ['ts', 'm3u8'],
      );
      expect(
        liveExtensionOrder(
          setting: LiveFormatSetting.hls,
          allowedFormats: ['m3u8'],
        ),
        ['m3u8'],
      );
      expect(liveExtensionOrder(setting: LiveFormatSetting.ts), ['ts', 'm3u8']);
    });
  });

  group('credentials', () {
    test('trims only the ends', () {
      expect(cleanCredential('  pass\n'), 'pass');
      expect(cleanCredential('​pass﻿'), 'pass');
      expect(cleanCredential(' pa ss\t'), 'pa ss');
      expect(cleanCredential('p​ass'), 'p​ass');
      expect(cleanCredential(' p@ss:w/rd?&#%+ é '), 'p@ss:w/rd?&#%+ é');
    });
    test('inner whitespace hint', () {
      expect(hasInnerWhitespace('pa ss'), isTrue);
      expect(hasInnerWhitespace('pass'), isFalse);
    });
  });
}
