// A fake Xtream Codes provider for tests (brief section 5.10).
//
// Every quirk the connection layer must survive can be switched on through
// [MockProvider]. Run standalone for manual testing:
//
//   dart run tool/mock_server/main.dart
//
// It serves invented data only: no real channels, streams or providers.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

enum StreamMode { normal, redirectToToken, closeImmediately, forbidden }

enum EpisodesShape { map, list }

class RecordedRequest {
  RecordedRequest(this.path, this.query, this.userAgent, this.at);

  final String path;
  final Map<String, String> query;
  final String? userAgent;
  final DateTime at;

  String? get action => query['action'];
}

/// Behaviour switches for one mock provider.
class MockProvider {
  String username = 'user';
  String password = 'pass';

  /// Overrides merged into the default `user_info`.
  Map<String, Object?> userInfo = {};
  Map<String, Object?> serverInfo = {};

  /// Send every number as a string, `auth` as "1", etc.
  bool numbersAsStrings = false;

  /// Bytes/text sent before the JSON (BOM, whitespace, PHP warnings).
  String bodyPrefix = '';
  String contentType = 'application/json';

  /// `gzip` or `deflate`.
  String? compression;

  /// Replace the login (no action) body entirely, e.g. `{}` or HTML.
  String? rawLoginBody;
  int? loginStatus;

  /// When set, requests whose User-Agent doesn't match get HTTP 403.
  RegExp? requireUserAgent;

  /// Every request gets a 301 to this base (scheme/host/port).
  Uri? redirectAllTo;

  int liveStreamCount = 30;
  int categoryCount = 3;

  /// Delay before `get_live_streams` (all at once) starts sending.
  Duration liveStreamsDelay = Duration.zero;

  /// `get_live_streams` without category_id never answers.
  bool liveStreamsHang = false;

  /// Pad each live stream so the full list reaches roughly this size.
  int? liveStreamsTargetBytes;

  /// Junk shapes: false/null/wrong types/duplicates/emoji.
  bool junkFields = false;

  EpisodesShape episodesShape = EpisodesShape.map;
  StreamMode streamMode = StreamMode.normal;

  /// Behave like a Stalker/MAG portal: `/c/` exists, `player_api.php`
  /// does not.
  bool portalOnly = false;

  /// A body to serve at `/playlist.m3u` (bytes, for encoding tests).
  Uint8List? playlist;

  final requests = <RecordedRequest>[];
  int _inFlight = 0;
  int maxInFlight = 0;

  Iterable<RecordedRequest> withAction(String? a) =>
      requests.where((r) => r.path.endsWith('player_api.php') && r.action == a);
}

class MockXtreamServer {
  MockXtreamServer._(this._server, this.provider, this.secure);

  final HttpServer _server;
  final MockProvider provider;
  final bool secure;

  static Future<MockXtreamServer> start(
    MockProvider provider, {
    SecurityContext? tls,
    int port = 0,
  }) async {
    final server = await shelf_io.serve(
      (Request r) => _handle(r, provider),
      InternetAddress.loopbackIPv4,
      port,
      securityContext: tls,
    );
    server.autoCompress = false;
    return MockXtreamServer._(server, provider, tls != null);
  }

  int get port => _server.port;

  /// `http://127.0.0.1:port` (or https://localhost:port with TLS, so the
  /// certificate's name matches).
  Uri get base => Uri(
    scheme: secure ? 'https' : 'http',
    host: secure ? 'localhost' : '127.0.0.1',
    port: port,
  );

  String get hostPort => '${base.host}:$port';

  Future<void> close() => _server.close(force: true);

  /// Test-only self-signed certificate (test/fixtures/tls).
  static SecurityContext testTlsContext(String fixturesDir) => SecurityContext()
    ..useCertificateChain('$fixturesDir/cert.pem')
    ..usePrivateKey('$fixturesDir/key.pem');
}

// ---------------------------------------------------------------------------

Future<Response> _handle(Request r, MockProvider p) async {
  p._inFlight++;
  if (p._inFlight > p.maxInFlight) p.maxInFlight = p._inFlight;
  try {
    return await _route(r, p);
  } finally {
    p._inFlight--;
  }
}

Future<Response> _route(Request r, MockProvider p) async {
  final path = '/${r.url.path}';
  final query = r.url.queryParameters;
  p.requests.add(
    RecordedRequest(path, query, r.headers['user-agent'], DateTime.now()),
  );

  if (p.redirectAllTo != null) {
    final target = p.redirectAllTo!.replace(
      path: path,
      query: r.url.hasQuery ? r.url.query : null,
    );
    return Response(301, headers: {'location': target.toString()});
  }

  if (p.requireUserAgent != null &&
      !p.requireUserAgent!.hasMatch(r.headers['user-agent'] ?? '')) {
    return Response.forbidden('Access denied');
  }

  final segs = r.url.pathSegments.where((s) => s.isNotEmpty).toList();

  if (segs.isNotEmpty && segs.first == 'c') {
    return _html('<html><body>Stalker portal</body></html>');
  }
  if (path == '/playlist.m3u' && p.playlist != null) {
    return Response.ok(
      p.playlist,
      headers: {'content-type': 'audio/x-mpegurl'},
    );
  }
  if (segs.isNotEmpty && segs.first == 'token') {
    return Response.ok(
      Uint8List.fromList(List.filled(8192, 0x47)),
      headers: {'content-type': 'video/mp2t'},
    );
  }
  if (segs.length == 4 &&
      (segs[0] == 'live' || segs[0] == 'movie' || segs[0] == 'series')) {
    return _stream(r, p, segs);
  }
  if (path.endsWith('player_api.php')) {
    if (p.portalOnly) return Response.notFound('Not found');
    return _api(r, p, query);
  }
  return Response.notFound('Not found');
}

Response _html(String body, {int status = 200}) => Response(
  status,
  body: body,
  headers: {'content-type': 'text/html; charset=utf-8'},
);

Response _stream(Request r, MockProvider p, List<String> segs) {
  // Path segments are already percent-decoded by shelf.
  if (segs[1] != p.username || segs[2] != p.password) {
    return Response(401, body: 'bad credentials in stream path');
  }
  switch (p.streamMode) {
    case StreamMode.forbidden:
      return Response.forbidden('max connections');
    case StreamMode.closeImmediately:
      return Response.ok(Uint8List(0), headers: {'content-type': 'video/mp2t'});
    case StreamMode.redirectToToken:
      return Response.found(
        r.requestedUri.replace(path: '/token/abc123/${segs[3]}', query: null),
      );
    case StreamMode.normal:
      return Response.ok(
        Uint8List.fromList(List.filled(8192, 0x47)),
        headers: {'content-type': 'video/mp2t'},
      );
  }
}

Object? _num(MockProvider p, Object? v) =>
    p.numbersAsStrings && v is num ? '$v' : v;

Future<Response> _api(Request r, MockProvider p, Map<String, String> q) async {
  if (p.loginStatus != null && q['action'] == null) {
    return Response(p.loginStatus!, body: 'error ${p.loginStatus}');
  }
  final credsOk = q['username'] == p.username && q['password'] == p.password;
  final action = q['action'];

  if (action == null) {
    if (p.rawLoginBody != null) return _body(p, p.rawLoginBody!);
    if (!credsOk) {
      return _json(p, {
        'user_info': {'auth': _num(p, 0)},
      });
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final ui = <String, Object?>{
      'username': p.username,
      'auth': p.numbersAsStrings ? '1' : 1,
      'status': 'Active',
      'exp_date': _num(p, now + 86400 * 90),
      'is_trial': _num(p, 0),
      'active_cons': _num(p, 0),
      'created_at': _num(p, now - 86400 * 300),
      'max_connections': _num(p, 2),
      'allowed_output_formats': ['m3u8', 'ts'],
      ...p.userInfo,
    };
    final si = <String, Object?>{
      'url': r.requestedUri.host,
      'port': '${r.requestedUri.port}',
      'https_port': '443',
      'server_protocol': r.requestedUri.scheme,
      'timezone': 'UTC',
      'timestamp_now': _num(p, now),
      ...p.serverInfo,
    };
    return _json(p, {'user_info': ui, 'server_info': si});
  }

  if (!credsOk) {
    return _json(p, {
      'user_info': {'auth': 0},
    });
  }

  switch (action) {
    case 'get_live_categories':
    case 'get_vod_categories':
    case 'get_series_categories':
      return _json(p, [
        for (var i = 1; i <= p.categoryCount; i++)
          {
            'category_id': _num(p, i),
            'category_name': 'Category $i',
            'parent_id': 0,
          },
      ]);
    case 'get_live_streams':
      return _liveStreams(p, q['category_id']);
    case 'get_vod_streams':
      return _json(p, [
        for (var i = 1; i <= 10; i++)
          {
            'stream_id': _num(p, 1000 + i),
            'name': 'Film $i',
            'category_id': '${(i % p.categoryCount) + 1}',
            'container_extension': i.isEven ? 'mkv' : 'mp4',
            'rating': _num(p, 6.5),
          },
      ]);
    case 'get_series':
      return _json(p, [
        for (var i = 1; i <= 5; i++)
          {
            'series_id': _num(p, 500 + i),
            'name': 'Show $i',
            'cover': i == 1 ? '' : 'http://img.invalid/$i.jpg',
            'category_id': '1',
            'backdrop_path': i == 2 ? <String>[] : ['http://img.invalid/b.jpg'],
          },
      ]);
    case 'get_series_info':
      final eps = [
        {
          'id': '9001',
          'episode_num': 1,
          'title': 'Pilot',
          'container_extension': 'mkv',
          'season': 1,
          'info': {'duration_secs': 2700},
        },
        {
          'id': 9002,
          'episode_num': '2',
          'title': '',
          'season': '1',
          'info': <Object>[],
        },
      ];
      return _json(p, {
        'info': {'name': 'Show', 'plot': 'A plot &amp; more'},
        'seasons': <Object>[],
        'episodes': p.episodesShape == EpisodesShape.map
            ? {
                '1': eps,
                '2': [
                  {'id': '9101', 'episode_num': 1, 'title': 'S2E1'},
                ],
              }
            : eps,
      });
    case 'get_short_epg':
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return _json(p, {
        'epg_listings': [
          {
            'title': base64.encode(utf8.encode('Morning News')),
            'description': base64.encode(utf8.encode('Headlines')),
            'start': '2020-01-01 06:00:00',
            'start_timestamp': '$now',
            'stop_timestamp': '${now + 1800}',
          },
        ],
      });
  }
  return _json(p, false);
}

Future<Response> _liveStreams(MockProvider p, String? categoryId) async {
  if (categoryId == null) {
    if (p.liveStreamsHang) {
      await Completer<void>().future; // never answers
    }
    if (p.liveStreamsDelay > Duration.zero) {
      await Future<void>.delayed(p.liveStreamsDelay);
    }
  }
  final cat = categoryId == null ? null : int.tryParse(categoryId);
  final count = p.liveStreamCount;
  final padTo = p.liveStreamsTargetBytes;
  final pad = padTo == null
      ? ''
      : 'x' * ((padTo ~/ count) - 200).clamp(0, 1 << 20);

  final items = <Map<String, Object?>>[];
  for (var i = 1; i <= count; i++) {
    final c = (i % p.categoryCount) + 1;
    if (cat != null && c != cat) continue;
    items.add({
      'num': _num(p, i),
      'name': p.junkFields && i == 3
          ? ''
          : p.junkFields && i == 4
          ? 'Émoji 📺 &amp; Co'
          : 'Channel $i',
      'stream_type': 'live',
      'stream_id': p.junkFields && i == 5 ? '1' : _num(p, i),
      'stream_icon': p.junkFields && i == 2
          ? false
          : 'http://img.invalid/$i.png',
      'epg_channel_id': p.junkFields ? null : 'ch$i',
      'added': p.junkFields ? false : _num(p, 1700000000),
      'category_id': '$c',
      'tv_archive': p.junkFields ? '1' : 0,
      'tv_archive_duration': p.junkFields ? <Object>[] : 0,
      if (pad.isNotEmpty) 'custom_sid': pad,
      if (p.junkFields) 'unexpected_key': {'nested': true},
    });
  }
  if (p.junkFields) items.add({'name': 'no id at all'});
  return _json(p, items, chunked: padTo != null);
}

Response _json(MockProvider p, Object? value, {bool chunked = false}) =>
    _body(p, jsonEncode(value), chunked: chunked);

Response _body(MockProvider p, String text, {bool chunked = false}) {
  var bytes = Uint8List.fromList(utf8.encode('${p.bodyPrefix}$text'));
  final headers = <String, String>{'content-type': p.contentType};
  if (p.compression == 'gzip') {
    bytes = Uint8List.fromList(GZipCodec().encode(bytes));
    headers['content-encoding'] = 'gzip';
  } else if (p.compression == 'deflate') {
    bytes = Uint8List.fromList(ZLibCodec().encode(bytes));
    headers['content-encoding'] = 'deflate';
  }
  headers['content-length'] = '${bytes.length}';
  if (!chunked) return Response.ok(bytes, headers: headers);
  // Stream in 64 KB chunks with tiny pauses so progress is observable.
  Stream<List<int>> chunks() async* {
    const size = 64 * 1024;
    for (var i = 0; i < bytes.length; i += size) {
      yield bytes.sublist(i, i + size > bytes.length ? bytes.length : i + size);
      if (i % (size * 64) == 0) await Future<void>.delayed(Duration.zero);
    }
  }

  return Response.ok(chunks(), headers: headers);
}
