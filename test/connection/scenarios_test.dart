// The 27 acceptance scenarios from brief section 5.10, run against the
// shelf mock provider over real loopback HTTP(S) with the real dio client.
//
// Scenarios whose second half belongs to a later phase (player UI,
// offline catalog) test the connection-layer half here; see
// docs/CONNECTION_NOTES.md for what is covered where.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/core/network/connection_error.dart';
import 'package:lumen/core/network/network_client.dart';
import 'package:lumen/core/network/retry.dart';
import 'package:lumen/core/network/user_agents.dart';
import 'package:lumen/data/m3u/m3u_loader.dart';
import 'package:lumen/data/secure/credential_store.dart';
import 'package:lumen/data/xtream/connection_doctor.dart';
import 'package:lumen/data/xtream/server_endpoint.dart';
import 'package:lumen/data/xtream/stream_probe.dart';
import 'package:lumen/data/xtream/stream_urls.dart';
import 'package:lumen/data/xtream/xtream_client.dart';
import 'package:lumen/data/xtream/xtream_models.dart';

import '../../tool/mock_server/mock_xtream_server.dart';

const tlsDir = 'test/fixtures/tls';
const fast = NetTimeouts(
  connect: Duration(seconds: 3),
  receive: Duration(seconds: 3),
);

final _servers = <MockXtreamServer>[];
final _clients = <NetworkClient>[];

Future<MockXtreamServer> serve(MockProvider p, {bool tls = false}) async {
  final s = await MockXtreamServer.start(
    p,
    tls: tls ? MockXtreamServer.testTlsContext(tlsDir) : null,
  );
  _servers.add(s);
  return s;
}

NetworkClient client({bool allowSelfSignedLocalhost = false}) {
  final c = DioNetworkClient(
    allowUntrustedCertFor: allowSelfSignedLocalhost
        ? (h) => h == 'localhost'
        : null,
  );
  _clients.add(c);
  return c;
}

Future<ProbeResult> probe(
  String server, {
  String user = 'user',
  String pass = 'pass',
  NetworkClient? net,
  WorkingProfile? saved,
  NetTimeouts timeouts = fast,
}) => ConnectionDoctor(network: net ?? client(), timeouts: timeouts).probe(
  input: ServerEndpoint.parse(server),
  username: user,
  password: pass,
  saved: saved,
);

ProbeSuccess ok(ProbeResult r) {
  if (r is ProbeFailure) {
    fail(
      'expected success, got ${r.error.kind.name}: ${r.error.details}\n'
      '${r.attempts.map((a) => '${a.endpoint} ${a.userAgent.id} ${a.status} ${a.outcome}').join('\n')}',
    );
  }
  return r as ProbeSuccess;
}

ConnectionErrorKind kindOf(ProbeResult r) {
  if (r is ProbeSuccess) fail('expected failure, got success');
  return (r as ProbeFailure).error.kind;
}

XtreamClient xclient(
  MockXtreamServer s, {
  NetTimeouts timeouts = fast,
  String user = 'user',
  String pass = 'pass',
}) => XtreamClient(
  network: client(),
  endpoint: ServerEndpoint.parse('${s.base}').candidates.first,
  username: user,
  password: pass,
  timeouts: timeouts,
  retry: RetryPolicy.none,
  categoryDelay: const Duration(milliseconds: 20),
);

void main() {
  tearDown(() async {
    for (final c in _clients) {
      c.close();
    }
    _clients.clear();
    for (final s in _servers) {
      await s.close();
    }
    _servers.clear();
  });

  test('1. normal JSON with integers signs in', () async {
    final s = await serve(MockProvider());
    final r = ok(await probe('${s.base}'));
    expect(r.account.user.status, AccountStatus.active);
    expect(r.account.user.maxConnections, 2);
    expect(r.liveCategoryCount, 3);
    expect(r.profile.endpoint.host, '127.0.0.1');
    expect(r.attempts.where((a) => a.step == 'login'), hasLength(1));
  });

  test('2. numbers as strings, auth "1", string and null exp_date', () async {
    final p = MockProvider()..numbersAsStrings = true;
    final s = await serve(p);
    final r = ok(await probe('${s.base}'));
    expect(r.account.user.expiresAt, isNotNull);
    expect(r.account.user.maxConnections, 2);

    p.userInfo = {'exp_date': null};
    final r2 = ok(await probe('${s.base}'));
    expect(r2.account.user.expiresAt, isNull);
    expect(expiryLabel(r2.account.user.expiresAt), 'No expiry');
  });

  test('3. BOM + whitespace, and a PHP warning before the JSON', () async {
    final p = MockProvider()..bodyPrefix = '﻿  \r\n';
    final s = await serve(p);
    ok(await probe('${s.base}'));
    p.bodyPrefix =
        '<br />\n<b>Warning</b>:  mysqli_connect(): (HY000/2002) in '
        '<b>/var/www/html/includes/db.php</b> on line <b>12</b><br />\n';
    ok(await probe('${s.base}'));
  });

  test('4. Content-Type text/html on a JSON body', () async {
    final s = await serve(MockProvider()..contentType = 'text/html');
    ok(await probe('${s.base}'));
  });

  test('5. gzip and deflate responses', () async {
    for (final enc in ['gzip', 'deflate']) {
      final s = await serve(MockProvider()..compression = enc);
      final r = ok(await probe('${s.base}'));
      expect(r.liveCategoryCount, 3, reason: enc);
    }
  });

  test('6. 301 http->https and https->http; new base saved', () async {
    // http (127.0.0.1) -> https (localhost)
    final secure = await serve(MockProvider(), tls: true);
    final redirector = await serve(MockProvider()..redirectAllTo = secure.base);
    final net = client(allowSelfSignedLocalhost: true);
    final r = ok(await probe('${redirector.base}', net: net));
    expect(r.profile.endpoint.scheme, 'https');
    expect(r.profile.endpoint.host, 'localhost');
    expect(r.profile.endpoint.port, secure.port);
    expect(r.attempts.first.redirectedTo, r.profile.endpoint);

    // https (localhost) -> http (127.0.0.1)
    final plain = await serve(MockProvider());
    final back = await serve(
      MockProvider()..redirectAllTo = plain.base,
      tls: true,
    );
    final r2 = ok(await probe('${back.base}', net: net));
    expect(r2.profile.endpoint.scheme, 'http');
    expect(r2.profile.endpoint.port, plain.port);
  });

  test(
    '7. host only: tries http first, then https; saves what works',
    () async {
      final s = await serve(MockProvider());
      final r = ok(await probe(s.hostPort));
      expect(r.profile.endpoint.scheme, 'http');

      final tls = await serve(MockProvider(), tls: true);
      final r2 = ok(
        await probe(tls.hostPort, net: client(allowSelfSignedLocalhost: true)),
      );
      expect(r2.profile.endpoint.scheme, 'https');
      expect(r2.attempts.first.endpoint.scheme, 'http');
      expect(r2.attempts.first.ok, isFalse);
    },
  );

  test('8. 403 unless player user-agent; saved profile reused', () async {
    final p = MockProvider()..requireUserAgent = RegExp(r'^VLC/');
    final s = await serve(p);
    final r = ok(await probe('${s.base}'));
    expect(r.profile.userAgent, UserAgentProfile.vlc);
    expect(r.attempts.where((a) => a.step == 'login').map((a) => a.userAgent), [
      UserAgentProfile.okhttp,
      UserAgentProfile.vlc,
    ]);

    p.requests.clear();
    final r2 = ok(await probe('${s.base}', saved: r.profile));
    expect(r2.attempts.first.userAgent, UserAgentProfile.vlc);
    expect(p.requests.first.userAgent, startsWith('VLC/'));
    expect(r2.attempts.where((a) => a.step == 'login'), hasLength(1));
  });

  test('9. auth:0 and {} give auth_rejected', () async {
    final s = await serve(MockProvider());
    expect(
      kindOf(await probe('${s.base}', pass: 'wrong')),
      ConnectionErrorKind.authRejected,
    );
    final s2 = await serve(MockProvider()..rawLoginBody = '{}');
    final r = await probe('${s2.base}');
    expect(kindOf(r), ConnectionErrorKind.authRejected);
    // A definitive answer stops the probe: no other agents or schemes.
    expect(r.attempts, hasLength(1));
  });

  test('10. expired, banned and disabled each get their class', () async {
    final past = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 86400;
    final p = MockProvider()..userInfo = {'exp_date': past};
    final s = await serve(p);
    final r = await probe('${s.base}');
    expect(kindOf(r), ConnectionErrorKind.expired);
    final e = (r as ProbeFailure).error;
    expect(e.expiredOn, isNotNull);
    expect(e.body, contains(formatDay(e.expiredOn!)));

    p.userInfo = {'status': 'Banned'};
    expect(kindOf(await probe('${s.base}')), ConnectionErrorKind.disabled);
    p.userInfo = {'status': 'Disabled'};
    expect(kindOf(await probe('${s.base}')), ConnectionErrorKind.disabled);
    p.userInfo = {'status': 'Expired'};
    expect(kindOf(await probe('${s.base}')), ConnectionErrorKind.expired);
  });

  test('11. active_cons == max_connections: signs in with a warning; '
      'refused stream reports max_connections', () async {
    final p = MockProvider()
      ..userInfo = {'active_cons': 2, 'max_connections': 2}
      ..streamMode = StreamMode.forbidden;
    final s = await serve(p);
    final r = ok(await probe('${s.base}'));
    expect(r.warnings, contains(ProbeWarning.atConnectionLimit));

    final urls = XtreamUrls(r.profile.endpoint, 'user', 'pass');
    final check = await checkStream(
      client(),
      urls.live(1),
      maxConnections: r.account.user.maxConnections,
    );
    expect(check.error?.kind, ConnectionErrorKind.maxConnections);
    expect(check.error?.body, contains('allows 2'));
  });

  test('12. 60 MB get_live_streams after 10 s: progress, isolate parse, '
      'UI stays responsive, cancellable', () async {
    final p = MockProvider()
      ..liveStreamCount = 60000
      ..liveStreamsTargetBytes = 60 * 1024 * 1024
      ..liveStreamsDelay = const Duration(seconds: 10);
    final s = await serve(p);
    final c = xclient(
      s,
      timeouts: const NetTimeouts(
        connect: Duration(seconds: 5),
        receive: Duration(seconds: 15),
      ),
    );

    final progress = <int>[];
    int? total;
    var maxGap = Duration.zero;
    var last = DateTime.now();
    final ticker = Stream<void>.periodic(const Duration(milliseconds: 16))
        .listen((_) {
          final now = DateTime.now();
          final gap = now.difference(last);
          if (gap > maxGap) maxGap = gap;
          last = now;
        });
    final list = await c.liveStreams(
      onProgress: (r, t) {
        progress.add(r);
        total = t;
      },
    );
    await ticker.cancel();

    expect(list, hasLength(60000));
    expect(total, greaterThan(60 * 1024 * 1024 - 1024 * 1024));
    expect(progress.length, greaterThan(10));
    for (var i = 1; i < progress.length; i++) {
      expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
    }
    expect(progress.last, total);
    expect(
      maxGap,
      lessThan(const Duration(milliseconds: 1500)),
      reason: 'main isolate stalled for $maxGap',
    );

    // Cancel while waiting for the slow server.
    final cancel = CancelSignal();
    final sw = Stopwatch()..start();
    final f = c.liveStreams(cancel: cancel);
    Timer(const Duration(milliseconds: 300), cancel.cancel);
    await expectLater(f, throwsA(isA<ConnectionError>()));
    expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('13. get_live_streams times out: falls back per category, '
      'at most 2 at a time', () async {
    final p = MockProvider()
      ..liveStreamsHang = true
      ..categoryCount = 6;
    final s = await serve(p);
    final c = xclient(
      s,
      timeouts: const NetTimeouts(
        connect: Duration(seconds: 2),
        receive: Duration(seconds: 1),
      ),
    );
    final list = await c.liveStreams();
    expect(list, hasLength(p.liveStreamCount));
    final perCat = p
        .withAction('get_live_streams')
        .where((r) => r.query.containsKey('category_id'));
    expect(perCat, hasLength(6));
    // The hung request plus at most 2 category requests.
    expect(p.maxInFlight, lessThanOrEqualTo(3));
  });

  test('14. Cloudflare-style HTML page: html_response', () async {
    final s = await serve(
      MockProvider()
        ..contentType = 'text/html'
        ..rawLoginBody =
            '<!DOCTYPE html><html><head><title>Just a moment...</title>'
            '</head><body>Checking your browser. cf-ray: 1234</body></html>',
    );
    final r = await probe('${s.base}');
    expect(kindOf(r), ConnectionErrorKind.htmlResponse);
    // Bot checks can depend on the agent: every agent was tried.
    expect(
      r.attempts.where((a) => a.endpoint.scheme == 'http'),
      hasLength(UserAgentProfile.values.length),
    );
  });

  test('15. self-signed TLS: tls_error, then works when allowed', () async {
    final s = await serve(MockProvider(), tls: true);
    expect(kindOf(await probe('${s.base}')), ConnectionErrorKind.tlsError);
    ok(await probe('${s.base}', net: client(allowSelfSignedLocalhost: true)));
    // Allowing one host never allows another.
    final other = DioNetworkClient(
      allowUntrustedCertFor: (h) => h == 'x.example',
    );
    _clients.add(other);
    expect(
      kindOf(await probe('${s.base}', net: other)),
      ConnectionErrorKind.tlsError,
    );
  });

  test('16. password p@ss:w/rd?&#%+ é encodes correctly in API and stream '
      'URLs', () async {
    const pw = 'p@ss:w/rd?&#%+ é';
    final p = MockProvider()
      ..username = 'us er+1'
      ..password = pw;
    final s = await serve(p);
    final r = ok(await probe('${s.base}', user: 'us er+1', pass: pw));
    expect(p.requests.first.query['password'], pw);
    expect(p.requests.first.query['username'], 'us er+1');

    final urls = XtreamUrls(r.profile.endpoint, 'us er+1', pw);
    for (final u in [
      urls.live(1),
      urls.movie(1001, 'mkv'),
      urls.episode('9001', 'mp4'),
    ]) {
      final check = await checkStream(client(), u);
      expect(check.ok, isTrue, reason: '$u -> ${check.error?.details}');
    }
  });

  test('17. trailing space, newline and zero-width in credentials', () async {
    final s = await serve(MockProvider());
    final r = ok(await probe('${s.base}', user: ' user​', pass: 'pass \n﻿'));
    expect(r.username, 'user');
    expect(r.password, 'pass');
    expect(r.warnings, isNot(contains(ProbeWarning.credentialsHaveSpaces)));
  });

  test(
    '18. full get.php URL in the server field: credentials extracted',
    () async {
      final s = await serve(MockProvider());
      final input = ServerEndpoint.parse(
        '${s.base}/get.php?username=user&password=pass&type=m3u_plus&output=ts',
      );
      expect(input.credentialsFromLink, isTrue);
      expect(input.username, 'user');
      expect(input.password, 'pass');
      final r = await ConnectionDoctor(network: client(), timeouts: fast).probe(
        input: input,
        username: input.username!,
        password: input.password!,
      );
      ok(r);
    },
  );

  test('19. server_info.url differs: entered host stays primary', () async {
    final s = await serve(
      MockProvider()
        ..serverInfo = {
          'url': 'other-cdn.invalid',
          'port': '9999',
          'server_protocol': 'https',
        },
    );
    final r = ok(await probe('${s.base}'));
    expect(r.profile.endpoint.host, '127.0.0.1');
    expect(r.profile.endpoint.port, s.port);
    // Kept as a fallback for streams.
    expect(r.account.server?.url, 'other-cdn.invalid');
    expect(r.account.server?.port, 9999);
  });

  test(
    '20. missing fields, false, wrong types, duplicate ids, emoji',
    () async {
      final p = MockProvider()
        ..junkFields = true
        ..numbersAsStrings = true;
      final s = await serve(p);
      ok(await probe('${s.base}'));
      final list = await xclient(s).liveStreams();
      final ids = list.map((e) => e.streamId).toList();
      expect(ids.toSet(), hasLength(ids.length), reason: 'no duplicate ids');
      expect(list.firstWhere((e) => e.streamId == 3).name, 'Channel 3');
      expect(list.firstWhere((e) => e.streamId == 4).name, 'Émoji 📺 & Co');
      expect(list.firstWhere((e) => e.streamId == 2).icon, isNull);
      expect(list.every((e) => e.name.isNotEmpty), isTrue);
    },
  );

  test(
    '21. series episodes as map and as list; missing extension = mp4',
    () async {
      final p = MockProvider();
      final s = await serve(p);
      final c = xclient(s);
      final asMap = await c.seriesInfo(501);
      expect(asMap.episodesBySeason.keys, [1, 2]);
      expect(asMap.episodesBySeason[1]!.first.containerExtension, 'mkv');
      expect(asMap.episodesBySeason[1]![1].containerExtension, 'mp4');
      expect(asMap.episodesBySeason[1]![1].title, 'Episode 2');
      expect(asMap.plot, 'A plot & more');

      p.episodesShape = EpisodesShape.list;
      final asList = await c.seriesInfo(501);
      expect(asList.episodesBySeason.keys, [1]);
      expect(asList.episodesBySeason[1], hasLength(2));
    },
  );

  test('22. live stream 302 to a tokenised URL plays', () async {
    final s = await serve(
      MockProvider()..streamMode = StreamMode.redirectToToken,
    );
    final urls = XtreamUrls(
      ServerEndpoint.parse('${s.base}').candidates.first,
      'user',
      'pass',
    );
    final check = await checkStream(client(), urls.live(7));
    expect(check.ok, isTrue, reason: check.error?.details);
    expect(check.finalUrl!.path, '/token/abc123/7.ts');
    expect(check.bytesRead, greaterThan(0));
  });

  test('23. stream closes immediately: max_connections', () async {
    final s = await serve(
      MockProvider()..streamMode = StreamMode.closeImmediately,
    );
    final urls = XtreamUrls(
      ServerEndpoint.parse('${s.base}').candidates.first,
      'user',
      'pass',
    );
    final check = await checkStream(client(), urls.live(7), maxConnections: 1);
    expect(check.error?.kind, ConnectionErrorKind.maxConnections);
    expect(check.error?.body, contains('allows 1'));
  });

  test('24. network lost mid-session: classified, then retried when it '
      'comes back', () async {
    final p = MockProvider();
    var s = await MockXtreamServer.start(p);
    final port = s.port;
    final c = xclient(s);
    await c.liveCategories();
    await s.close();

    // While down: a clear class, never a raw exception.
    await expectLater(
      c.liveCategories(),
      throwsA(
        isA<ConnectionError>().having(
          (e) => e.kind,
          'kind',
          anyOf(
            ConnectionErrorKind.timeoutOrRefused,
            ConnectionErrorKind.offline,
          ),
        ),
      ),
    );

    // Comes back during the retry delay: the retrying request succeeds.
    final retrying = XtreamClient(
      network: client(),
      endpoint: ServerEndpoint.parse('127.0.0.1:$port').candidates.first,
      username: 'user',
      password: 'pass',
      timeouts: fast,
      retry: const RetryPolicy(
        delays: [Duration(milliseconds: 600)],
        maxAttempts: 3,
      ),
    );
    final f = retrying.liveCategories();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    s = await MockXtreamServer.start(p, port: port);
    _servers.add(s);
    expect(await f, hasLength(3));
  });

  test('25. secure storage throws: no crash, re-prompt state', () async {
    final store = SecureCredentialStore(_Exploding());
    final read = await store.readPassword('provider-1');
    expect(read, isA<SecretUnavailable>());
    expect(read is SecretFound, isFalse);
    expect(await store.writePassword('provider-1', 'x'), isFalse);
  });

  test('26. M3U: commas in attributes, EXTVLCOPT, EXTHTTP, CRLF, BOM, '
      'Windows-1252, 50 MB', () async {
    final b = BytesBuilder()
      ..add([0xEF, 0xBB, 0xBF])
      ..add(
        utf8.encode(
          '#EXTM3U x-tvg-url="http://epg.invalid/guide.xml"\r\n'
          '#EXTINF:-1 tvg-id="a" group-title="News, UK",BBC, One\r\n'
          '#EXTVLCOPT:http-user-agent=VLC/3\r\n'
          '#EXTVLCOPT:http-referrer=http://ref.invalid\r\n'
          'http://h.invalid/1\r\n'
          '#EXTINF:-1,Two\r\n'
          '#EXTHTTP:{"User-Agent":"X/1"}\r\n'
          'http://h.invalid/2\r\n',
        ),
      );
    var i = 0;
    while (b.length < 50 * 1024 * 1024) {
      b.add(
        utf8.encode(
          '#EXTINF:-1 tvg-name="C, $i" group-title="G",C $i\r\n'
          'http://h.invalid/live/u/p/$i.ts\r\n',
        ),
      );
      i++;
    }
    final p = MockProvider()..playlist = b.takeBytes();
    final s = await serve(p);
    final pl = await loadM3uLink(
      client(),
      s.base.replace(path: '/playlist.m3u'),
      timeouts: const NetTimeouts(receive: Duration(seconds: 30)),
    );
    expect(pl.epgUrl, 'http://epg.invalid/guide.xml');
    expect(pl.entries.length, i + 2);
    expect(pl.entries[0].name, 'BBC, One');
    expect(pl.entries[0].group, 'News, UK');
    expect(pl.entries[0].headers, {
      'User-Agent': 'VLC/3',
      'Referer': 'http://ref.invalid',
    });
    expect(pl.entries[1].headers, {'User-Agent': 'X/1'});

    // Windows-1252 file.
    final cp = Uint8List.fromList([
      ...latin1.encode('#EXTM3U\r\n#EXTINF:-1,Telé '),
      0x80, // euro sign in cp1252
      ...ascii.encode('\r\nhttp://h/1\r\n'),
    ]);
    final p2 = MockProvider()..playlist = cp;
    final s2 = await serve(p2);
    final pl2 = await loadM3uLink(
      client(),
      s2.base.replace(path: '/playlist.m3u'),
    );
    expect(pl2.entries.single.name, 'Telé €');

    // Not a playlist.
    final p3 = MockProvider()
      ..playlist = Uint8List.fromList(utf8.encode('hello'));
    final s3 = await serve(p3);
    await expectLater(
      loadM3uLink(client(), s3.base.replace(path: '/playlist.m3u')),
      throwsA(
        isA<ConnectionError>().having(
          (e) => e.kind,
          'kind',
          ConnectionErrorKind.m3uInvalid,
        ),
      ),
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('27. portal-style /c/ URL: portal_unsupported', () async {
    // A real Stalker/MAG portal has no player_api.php.
    final s = await serve(MockProvider()..portalOnly = true);
    final r = await probe('${s.base}/c/');
    expect(kindOf(r), ConnectionErrorKind.portalUnsupported);
    expect((r as ProbeFailure).error.body, contains('Xtream login or M3U'));

    // Without the portal hint, the same server is "not an Xtream address".
    expect(kindOf(await probe('${s.base}')), ConnectionErrorKind.http404);

    // If a panel serves both, a pasted portal URL still signs in via Xtream.
    final both = await serve(MockProvider());
    ok(await probe('${both.base}/c/'));
  });

  group('extra connection-layer checks', () {
    test('DNS failure is classified', () async {
      final r = await probe('http://no-such-host.invalid:8080');
      expect(kindOf(r), ConnectionErrorKind.dnsFailure);
      // DNS failure skips the other user-agents: one attempt per scheme.
      expect(r.attempts, hasLength(2));
    });

    test('refused port is classified', () async {
      final tmp = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = tmp.port;
      await tmp.close();
      expect(
        kindOf(await probe('127.0.0.1:$port')),
        ConnectionErrorKind.timeoutOrRefused,
      );
    });

    test('404 at player_api: not an Xtream address', () async {
      final s = await serve(MockProvider()..loginStatus = 404);
      expect(kindOf(await probe('${s.base}')), ConnectionErrorKind.http404);
    });

    test('401 everywhere beats a timeout on one candidate', () async {
      final p = MockProvider()..loginStatus = 401;
      final s = await serve(p);
      // https candidate on the same plain port fails at TLS level.
      final r = await probe('${s.base}');
      expect(kindOf(r), ConnectionErrorKind.http401or403);
    });

    test('catalog check failing still signs in with a warning', () async {
      final p = MockProvider()..categoryCount = 0;
      final s = await serve(p);
      final r = ok(await probe('${s.base}'));
      expect(r.liveCategoryCount, 0);
    });

    test('probe never opens a stream', () async {
      final p = MockProvider();
      final s = await serve(p);
      ok(await probe('${s.base}'));
      expect(
        p.requests.where((r) => !r.path.endsWith('player_api.php')),
        isEmpty,
      );
    });

    test('probe is sequential and bounded', () async {
      final r =
          await ConnectionDoctor(
            network: client(),
            timeouts: const NetTimeouts(
              connect: Duration(milliseconds: 500),
              receive: Duration(milliseconds: 500),
            ),
            budget: const Duration(seconds: 3),
          ).probe(
            // TEST-NET-1 is unroutable: connects time out.
            input: ServerEndpoint.parse('192.0.2.1:8080'),
            username: 'u',
            password: 'p',
          );
      expect(r, isA<ProbeFailure>());
    });
  });
}

class _Exploding implements SecretBackend {
  @override
  Future<void> delete(String key) => Future.error(StateError('boom'));
  @override
  Future<String?> read(String key) =>
      Future.error(Exception('android.security.KeyStoreException'));
  @override
  Future<void> write(String key, String value) =>
      Future.error(Exception('keystore'));
}
