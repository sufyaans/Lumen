import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/core/network/connection_error.dart';
import 'package:lumen/core/network/network_client.dart';
import 'package:lumen/core/network/redaction.dart';
import 'package:lumen/core/network/retry.dart';
import 'package:lumen/core/network/user_agents.dart';
import 'package:lumen/core/utils/punycode.dart';
import 'package:lumen/data/secure/credential_store.dart';
import 'package:lumen/data/xtream/connection_doctor.dart';
import 'package:lumen/data/xtream/server_endpoint.dart';
import 'package:lumen/data/xtream/xtream_client.dart';
import 'package:lumen/features/diagnostics/diagnostic_report.dart';

NetResponse res(int status, [Map<String, String> h = const {}]) => NetResponse(
  status: status,
  headers: h,
  bytes: Uint8List(0),
  finalUrl: Uri.parse('http://x/'),
);

class ThrowingBackend implements SecretBackend {
  @override
  Future<void> delete(String key) async => throw StateError('keystore');
  @override
  Future<String?> read(String key) async =>
      throw Exception('KeyStoreException: key permanently invalidated');
  @override
  Future<void> write(String key, String value) async =>
      throw Exception('keystore');
}

class MapBackend implements SecretBackend {
  final m = <String, String>{};
  @override
  Future<void> delete(String key) async => m.remove(key);
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
}

void main() {
  group('redaction', () {
    test('query credentials', () {
      final s = Redactor.redact(
        'GET http://h:8080/player_api.php?username=bob&password=s3cr3t&action=x',
      );
      expect(s, isNot(contains('bob')));
      expect(s, isNot(contains('s3cr3t')));
      expect(s, contains('action=x'));
    });
    test('userinfo and stream paths', () {
      expect(
        Redactor.redact('http://bob:pw@h.example/x'),
        'http://***@h.example/x',
      );
      expect(
        Redactor.redact(
          'http://h/live/bob/pw/1.ts and http://h/movie/a/b/2.mp4',
        ),
        'http://h/live/***/***/1.ts and http://h/movie/***/***/2.mp4',
      );
    });
    test('known secrets in any encoding', () {
      const pw = 'p@ss w+rd';
      final s = Redactor.redact(
        'a p@ss w+rd b ${Uri.encodeComponent(pw)} c ${Uri.encodeQueryComponent(pw)}',
        secrets: [pw],
      );
      expect(s, 'a *** b *** c ***');
    });
    test('NetException.toString is redacted', () {
      final e = NetException(
        NetFailureKind.timeout,
        'x',
        url: Uri.parse('http://h/player_api.php?username=u&password=p'),
      );
      expect('$e', isNot(contains('password=p')));
    });
  });

  group('retry policy', () {
    test('retries timeouts with 0.5 s then 1.5 s, three attempts', () async {
      final waits = <Duration>[];
      var calls = 0;
      await expectLater(
        getWithRetry(
          () async {
            calls++;
            throw NetException(NetFailureKind.timeout, 't');
          },
          sleep: (d) async => waits.add(d),
          random: Random(1),
        ),
        throwsA(isA<NetException>()),
      );
      expect(calls, 3);
      expect(waits, hasLength(2));
      expect(waits[0].inMilliseconds, inInclusiveRange(400, 600));
      expect(waits[1].inMilliseconds, inInclusiveRange(1200, 1800));
    });
    test('does not retry DNS or TLS failures', () async {
      for (final k in [NetFailureKind.dns, NetFailureKind.tls]) {
        var calls = 0;
        await expectLater(
          getWithRetry(() async {
            calls++;
            throw NetException(k, 'x');
          }, sleep: (_) async {}),
          throwsA(isA<NetException>()),
        );
        expect(calls, 1, reason: k.name);
      }
    });
    test('honours Retry-After on 429 and 503', () async {
      final waits = <Duration>[];
      var calls = 0;
      final r = await getWithRetry(() async {
        calls++;
        return calls == 1 ? res(429, {'retry-after': '3'}) : res(200);
      }, sleep: (d) async => waits.add(d));
      expect(r.status, 200);
      expect(waits, [const Duration(seconds: 3)]);
    });
    test('Retry-After too long returns the response', () async {
      final r = await getWithRetry(
        () async => res(503, {'retry-after': '3600'}),
        sleep: (_) async => fail('should not wait'),
      );
      expect(r.status, 503);
    });
    test('does not retry 401', () async {
      var calls = 0;
      final r = await getWithRetry(() async {
        calls++;
        return res(401);
      }, sleep: (_) async {});
      expect(r.status, 401);
      expect(calls, 1);
    });
    test('cancellation stops immediately', () async {
      final c = CancelSignal();
      var calls = 0;
      final f = getWithRetry(
        () async {
          calls++;
          throw NetException(NetFailureKind.timeout, 't');
        },
        cancel: c,
        sleep: (_) async => c.cancel(),
      );
      await expectLater(
        f,
        throwsA(
          isA<NetException>().having(
            (e) => e.kind,
            'kind',
            NetFailureKind.cancelled,
          ),
        ),
      );
      expect(calls, 1);
    });
    test('Retry-After as HTTP date', () {
      final now = DateTime.utc(2015, 10, 21, 7, 27, 50);
      expect(
        RetryPolicy.parseRetryAfter('Wed, 21 Oct 2015 07:28:00 GMT', now: now),
        const Duration(seconds: 10),
      );
      expect(RetryPolicy.parseRetryAfter('nonsense'), isNull);
    });
  });

  group('error classification', () {
    test('status codes', () {
      expect(classifyStatus(res(200)), isNull);
      expect(classifyStatus(res(401))!.kind, ConnectionErrorKind.http401or403);
      expect(classifyStatus(res(403))!.kind, ConnectionErrorKind.http401or403);
      expect(classifyStatus(res(404))!.kind, ConnectionErrorKind.http404);
      expect(
        classifyStatus(res(502))!.kind,
        ConnectionErrorKind.timeoutOrRefused,
      );
    });
    test('transport failures', () {
      ConnectionErrorKind k(NetFailureKind f) =>
          classifyNetException(NetException(f, '')).kind;
      expect(k(NetFailureKind.dns), ConnectionErrorKind.dnsFailure);
      expect(k(NetFailureKind.refused), ConnectionErrorKind.timeoutOrRefused);
      expect(k(NetFailureKind.timeout), ConnectionErrorKind.timeoutOrRefused);
      expect(k(NetFailureKind.tls), ConnectionErrorKind.tlsError);
      expect(k(NetFailureKind.offline), ConnectionErrorKind.offline);
    });
    test('every class has plain-language copy without jargon headlines', () {
      for (final kind in ConnectionErrorKind.values) {
        final e = ConnectionError(kind);
        expect(e.title, isNotEmpty);
        expect(e.body, isNotEmpty);
        for (final jargon in ['CORS', 'HTTP', '403', '401', 'Exception']) {
          expect(e.title, isNot(contains(jargon)), reason: kind.name);
        }
      }
    });
    test('placeholders', () {
      expect(
        ConnectionError(
          ConnectionErrorKind.expired,
          expiredOn: DateTime.utc(2024, 3, 9, 12),
        ).body,
        contains('9 Mar 2024'),
      );
      expect(
        const ConnectionError(
          ConnectionErrorKind.maxConnections,
          maxConnections: 2,
        ).body,
        contains('allows 2'),
      );
    });
    test('401 beats timeout when picking the most informative', () {
      expect(
        const ConnectionError(ConnectionErrorKind.http401or403).informativeness,
        greaterThan(
          const ConnectionError(ConnectionErrorKind.timeoutOrRefused)
              .informativeness,
        ),
      );
    });
  });

  test('punycode', () {
    expect(hostToAscii('bücher.example'), 'xn--bcher-kva.example');
    expect(hostToAscii('MÜNCHEN.de'), 'xn--mnchen-3ya.de');
    expect(hostToAscii('例え.テスト'), 'xn--r8jz45g.xn--zckzah');
    expect(hostToAscii('Plain.Example'), 'plain.example');
  });

  test('user-agent order with a saved profile', () {
    expect(UserAgentProfile.probeOrder().map((e) => e.id), [
      'okhttp',
      'vlc',
      'lavf',
      'app',
    ]);
    expect(
      UserAgentProfile.probeOrder(saved: UserAgentProfile.vlc).map((e) => e.id),
      ['vlc', 'okhttp', 'lavf', 'app'],
    );
  });

  group('diagnostic report', () {
    test('masks hosts', () {
      expect(maskHost('provider.example.com'), 'pr***.com');
      expect(maskHost('192.168.1.20'), '19***');
      expect(maskHost('ab'), 'ab***');
    });
    test('contains no credentials or stream URLs', () {
      const pw = 'Sup3r\$ecret!';
      final report = buildDiagnosticReport(
        osAndDevice: 'Android 14 · Pixel',
        attempts: [
          const ProbeAttempt(
            endpoint: ServerEndpoint(
              scheme: 'http',
              host: 'provider.example.com',
              port: 8080,
            ),
            userAgent: UserAgentProfile.okhttp,
            step: 'login',
            elapsed: Duration(milliseconds: 420),
            status: 403,
            outcome: ConnectionErrorKind.http401or403,
          ),
        ],
        result: const ConnectionError(
          ConnectionErrorKind.http401or403,
          details: 'HTTP 403 at http://provider.example.com:8080/live/bob/Sup3r\$ecret!/1.ts?username=bob&password=Sup3r\$ecret!',
        ),
        secrets: ['bob', pw],
      );
      expect(report, isNot(contains(pw)));
      expect(report, isNot(contains('bob')));
      expect(report, isNot(contains('/live/')));
      expect(report, isNot(contains('provider.example')));
      expect(report, contains('pr***.com'));
      expect(report, contains('ua=okhttp'));
      expect(report, contains('status=403'));
      expect(report, contains('420 ms'));
    });
  });

  group('credential store (scenario 25)', () {
    test('throwing keystore never crashes; read reports unavailable', () async {
      final s = SecureCredentialStore(ThrowingBackend());
      expect(await s.readPassword('p1'), isA<SecretUnavailable>());
      expect(await s.writePassword('p1', 'x'), isFalse);
      await s.deleteAll('p1');
    });
    test('missing after re-sign is reported as missing', () async {
      final s = SecureCredentialStore(MapBackend());
      expect(await s.readPassword('p1'), isA<SecretMissing>());
      expect(await s.writePassword('p1', 'pw'), isTrue);
      expect(await s.readPassword('p1'), isA<SecretFound>());
      await s.deleteAll('p1');
      expect(await s.readPassword('p1'), isA<SecretMissing>());
    });
  });
}
