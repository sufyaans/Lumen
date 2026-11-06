import '../../app/app_config.dart';

/// User-agent profiles tried during sign-in, in order (brief section 5.3).
/// Many panels block unknown clients and only allow player-like agents.
enum UserAgentProfile {
  okhttp('okhttp', 'okhttp/4.12.0'),
  vlc('vlc', 'VLC/3.0.20 LibVLC/3.0.20'),
  lavf('lavf', 'Lavf/60.16.100'),
  app('app', AppConfig.defaultUserAgent);

  const UserAgentProfile(this.id, this.value);

  /// Stable id stored on the provider record.
  final String id;
  final String value;

  static UserAgentProfile? byId(String? id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Saved profile first (if any), then the default order, no duplicates.
  static List<UserAgentProfile> probeOrder({UserAgentProfile? saved}) => [
    ?saved,
    for (final p in values)
      if (p != saved) p,
  ];
}
