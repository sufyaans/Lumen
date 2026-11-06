import 'server_endpoint.dart';

enum LiveFormatSetting { auto, ts, hls }

/// The one place stream URLs are built (brief 5.4). Credentials are always
/// added as encoded path segments, never by string concatenation.
class XtreamUrls {
  const XtreamUrls(this.endpoint, this.username, this.password);

  final ServerEndpoint endpoint;
  final String username;
  final String password;

  /// `{base}/live/{user}/{pass}/{id}.{ext}`
  Uri live(int streamId, {String ext = 'ts'}) =>
      endpoint.resolve(['live', username, password, '$streamId.$ext']);

  /// `{base}/{user}/{pass}/{id}`, used when the `/live/` form returns 404.
  Uri liveShort(int streamId) =>
      endpoint.resolve([username, password, '$streamId']);

  /// `{base}/movie/{user}/{pass}/{id}.{ext}`
  Uri movie(int streamId, String containerExtension) => endpoint.resolve([
    'movie',
    username,
    password,
    '$streamId.${_ext(containerExtension)}',
  ]);

  /// `{base}/series/{user}/{pass}/{episodeId}.{ext}`
  Uri episode(String episodeId, String containerExtension) => endpoint.resolve([
    'series',
    username,
    password,
    '$episodeId.${_ext(containerExtension)}',
  ]);

  /// `{base}/timeshift/{user}/{pass}/{minutes}/{YYYY-MM-DD:HH-mm}/{id}.ts`
  ///
  /// [start] is formatted as given; pass it already converted to the
  /// provider's timezone.
  Uri timeshift(int streamId, DateTime start, Duration duration) {
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp =
        '${start.year}-${two(start.month)}-${two(start.day)}:'
        '${two(start.hour)}-${two(start.minute)}';
    return endpoint.resolve([
      'timeshift',
      username,
      password,
      '${duration.inMinutes}',
      stamp,
      '$streamId.ts',
    ]);
  }

  /// `player_api.php` with credentials and optional action/params.
  Uri api([String? action, Map<String, String> params = const {}]) =>
      endpoint.resolve(
        ['player_api.php'],
        {
          'username': username,
          'password': password,
          'action': ?action,
          ...params,
        },
      );

  Uri xmltv() => endpoint.resolve(
    ['xmltv.php'],
    {'username': username, 'password': password},
  );

  static String _ext(String e) {
    final s = e.toLowerCase().replaceAll('.', '').trim();
    return s.isEmpty ? 'mp4' : s;
  }
}

/// Live extensions to try, in order (brief 5.4): the user's setting, what
/// the account allows, and what last worked for this provider.
List<String> liveExtensionOrder({
  required LiveFormatSetting setting,
  List<String> allowedFormats = const [],
  String? lastWorked,
}) {
  final allowed = allowedFormats.map((e) => e.toLowerCase()).toSet();
  final canTs = allowed.isEmpty || allowed.contains('ts');
  final canHls = allowed.isEmpty || allowed.contains('m3u8');
  switch (setting) {
    case LiveFormatSetting.ts:
      return ['ts', if (canHls) 'm3u8'];
    case LiveFormatSetting.hls:
      return ['m3u8', if (canTs) 'ts'];
    case LiveFormatSetting.auto:
      if (lastWorked == 'ts' || lastWorked == 'm3u8') {
        return [lastWorked!, lastWorked == 'ts' ? 'm3u8' : 'ts'];
      }
      if (allowed.contains('m3u8')) return ['m3u8', if (canTs) 'ts'];
      return ['ts', 'm3u8'];
  }
}
