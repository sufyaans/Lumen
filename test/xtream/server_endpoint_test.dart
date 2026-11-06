import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/core/network/connection_error.dart';
import 'package:lumen/data/xtream/server_endpoint.dart';

/// One row of the messy-input table.
class Case {
  const Case(
    this.input, {
    this.first,
    this.second,
    this.user,
    this.pass,
    this.portal = false,
    this.m3u = false,
    this.invalid = false,
  });

  final String input;

  /// Expected first and second candidate as `scheme://host[:port]/base`.
  final String? first;
  final String? second;
  final String? user;
  final String? pass;
  final bool portal;
  final bool m3u;
  final bool invalid;
}

const cases = <Case>[
  // 1-5: basics and whitespace
  Case(
    'http://provider.example:8080',
    first: 'http://provider.example:8080',
    second: 'https://provider.example:8080',
  ),
  Case(
    '  http://provider.example:8080/  ',
    first: 'http://provider.example:8080',
  ),
  Case('\thttp://provider.example\n', first: 'http://provider.example'),
  Case(' http://provider.example:8080 ', first: 'http://provider.example:8080'),
  Case(
    '​http://provi​der.example:80‍80﻿',
    first: 'http://provider.example:8080',
  ),
  // 6-10: missing / mixed-case scheme, flipping
  Case(
    'provider.example:8080',
    first: 'http://provider.example:8080',
    second: 'https://provider.example:8080',
  ),
  Case(
    'provider.example',
    first: 'http://provider.example',
    second: 'https://provider.example',
  ),
  Case(
    'HTTPS://Provider.EXAMPLE',
    first: 'https://provider.example',
    second: 'http://provider.example',
  ),
  Case('HTTP://PROVIDER.EXAMPLE:25461', first: 'http://provider.example:25461'),
  Case('http:/provider.example:8080', first: 'http://provider.example:8080'),
  // 11-14: smart quotes, wrapping
  Case('“http://provider.example:8080”', first: 'http://provider.example:8080'),
  Case('"http://provider.example"', first: 'http://provider.example'),
  Case('<http://provider.example:8080>', first: 'http://provider.example:8080'),
  Case("'provider.example:8080'", first: 'http://provider.example:8080'),
  // 15-19: IPs, IPv6, IDN
  Case('192.168.1.20:8000', first: 'http://192.168.1.20:8000'),
  Case('http://10.0.0.5', first: 'http://10.0.0.5'),
  Case('http://[2001:db8::1]:8080', first: 'http://[2001:db8::1]:8080'),
  Case('[::1]:8080', first: 'http://[::1]:8080'),
  Case(
    'http://bücher.example:8080',
    first: 'http://xn--bcher-kva.example:8080',
  ),
  // 20-27: known endpoints stripped, base path kept
  Case(
    'http://provider.example:8080/player_api.php',
    first: 'http://provider.example:8080',
  ),
  Case(
    'http://provider.example:8080/player_api.php?username=u&password=p&action=x',
    first: 'http://provider.example:8080',
    user: 'u',
    pass: 'p',
  ),
  Case(
    'http://provider.example:8080/xmltv.php?username=u&password=p',
    first: 'http://provider.example:8080',
    user: 'u',
    pass: 'p',
  ),
  Case(
    'http://provider.example/panel_api.php',
    first: 'http://provider.example',
  ),
  Case(
    'http://provider.example/iptv/player_api.php',
    first: 'http://provider.example/iptv',
  ),
  Case('http://provider.example/iptv/', first: 'http://provider.example/iptv'),
  Case(
    'http://provider.example:8080/live/user1/pa55/12345.ts',
    first: 'http://provider.example:8080',
    user: 'user1',
    pass: 'pa55',
  ),
  Case(
    'http://provider.example:8080/movie/user1/pa55/77.mkv',
    first: 'http://provider.example:8080',
    user: 'user1',
    pass: 'pa55',
  ),
  // 28-31: full playlist link pasted into the server field
  Case(
    'http://provider.example:8080/get.php?username=U&password=P&type=m3u_plus&output=ts',
    first: 'http://provider.example:8080',
    user: 'U',
    pass: 'P',
  ),
  Case(
    'provider.example:8080/get.php?username=me%40home&password=p%26q%23r',
    first: 'http://provider.example:8080',
    user: 'me@home',
    pass: 'p&q#r',
  ),
  Case(
    'http://provider.example/get.php?username=%20U%20&password=P%0A',
    first: 'http://provider.example',
    user: 'U',
    pass: 'P',
  ),
  Case(
    'http://user:secret@provider.example:8080',
    first: 'http://provider.example:8080',
    user: 'user',
    pass: 'secret',
  ),
  // 32-35: portals and playlists
  Case(
    'http://portal.example:8080/c/',
    first: 'http://portal.example:8080',
    portal: true,
  ),
  Case(
    'http://portal.example/stalker_portal/c/',
    first: 'http://portal.example',
    portal: true,
  ),
  Case(
    'http://portal.example/portal.php',
    first: 'http://portal.example',
    portal: true,
  ),
  Case(
    'https://cdn.example/lists/my.m3u8',
    first: 'https://cdn.example/lists/my.m3u8',
    m3u: true,
  ),
  // 36-38: LAN names
  Case('localhost:25461', first: 'http://localhost:25461'),
  Case('nas:8080', first: 'http://nas:8080'),
  Case('http://my-provider.co.uk', first: 'http://my-provider.co.uk'),
  // 39-50: rejected input
  Case('', invalid: true),
  Case('   \n\t ', invalid: true),
  Case('​​', invalid: true),
  Case('rtmp://provider.example/live', invalid: true),
  Case('rtsp://provider.example:554/stream', invalid: true),
  Case('udp://239.0.0.1:1234', invalid: true),
  Case('http://provider example.com', invalid: true),
  Case('http://', invalid: true),
  Case('http://:8080', invalid: true),
  Case('hello', invalid: true),
  Case('http://provider.example:99999', invalid: true),
  Case('http://provider.example:abc', invalid: true),
  Case('http://999.1.1.1', invalid: true),
  Case('just some text here', invalid: true),
  Case('http://exa_mple!.com', invalid: true),
];

String fmt(ServerEndpoint e) => '${e.scheme}://${e.displayHost}${e.basePath}';

void main() {
  test('table has at least 40 messy inputs', () {
    expect(cases.length, greaterThanOrEqualTo(40));
  });

  for (final (i, c) in cases.indexed) {
    test('case ${i + 1}: ${c.input.replaceAll(RegExp(r'\s'), '·')}', () {
      final r = ServerEndpoint.parse(c.input);
      if (c.invalid) {
        expect(r.isValid, isFalse, reason: 'should be rejected');
        expect(r.error?.kind, ConnectionErrorKind.invalidInput);
        return;
      }
      expect(r.error, isNull, reason: r.error?.details);
      if (c.first != null && !c.m3u) {
        expect(fmt(r.candidates.first), c.first);
      }
      if (c.second != null) expect(fmt(r.candidates[1]), c.second);
      expect(r.username, c.user);
      expect(r.password, c.pass);
      expect(r.credentialsFromLink, c.user != null && c.pass != null);
      expect(r.looksLikePortal, c.portal);
      expect(r.kind, c.m3u ? InputKind.m3uLink : InputKind.xtream);
    });
  }

  test('default ports only apply when no port given; no port guessing', () {
    final r = ServerEndpoint.parse('provider.example');
    expect(r.candidates.map((e) => e.effectivePort), [80, 443]);
    expect(r.candidates, hasLength(2));
    final p = ServerEndpoint.parse('provider.example:8080');
    expect(p.candidates.map((e) => e.effectivePort), [8080, 8080]);
  });

  test('API URLs encode every special character in credentials', () {
    final e = ServerEndpoint.parse('http://h.example:8080').candidates.first;
    const pw = 'p@ss:w/rd?&#%+ é';
    final uri = e.resolve(
      ['player_api.php'],
      {'username': 'u se@r', 'password': pw},
    );
    expect(uri.queryParameters['password'], pw);
    expect(uri.queryParameters['username'], 'u se@r');
    expect(uri.toString(), isNot(contains('p@ss:w/rd')));
  });

  test('endpoint JSON round trip', () {
    const e = ServerEndpoint(
      scheme: 'https',
      host: 'h.example',
      port: 8443,
      basePath: '/x',
    );
    expect(ServerEndpoint.fromJson(e.toJson()), e);
  });

  test('fromApiUrl keeps base path before the API file', () {
    final e = ServerEndpoint.fromApiUrl(
      Uri.parse('https://new.example:2083/pfx/player_api.php?username=a'),
    );
    expect(fmt(e), 'https://new.example:2083/pfx');
  });
}
