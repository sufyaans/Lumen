import 'package:flutter/foundation.dart';

import '../../core/network/connection_error.dart';
import 'tolerant_json.dart';

enum AccountStatus { active, expired, banned, disabled, trial, unknown }

@immutable
class UserInfo {
  const UserInfo({
    required this.auth,
    required this.status,
    this.statusRaw,
    this.expiresAt,
    this.maxConnections,
    this.activeConnections,
    this.isTrial = false,
    this.createdAt,
    this.allowedOutputFormats = const [],
    this.message,
  });

  /// `null` when the panel didn't send `auth`.
  final bool? auth;
  final AccountStatus status;
  final String? statusRaw;

  /// `null` means no expiry.
  final DateTime? expiresAt;
  final int? maxConnections;
  final int? activeConnections;
  final bool isTrial;
  final DateTime? createdAt;

  /// e.g. `['m3u8', 'ts', 'rtmp']`.
  final List<String> allowedOutputFormats;
  final String? message;

  bool get atConnectionLimit =>
      maxConnections != null &&
      maxConnections! > 0 &&
      activeConnections != null &&
      activeConnections! >= maxConnections!;

  static UserInfo parse(Map<String, Object?> j) {
    final statusRaw = asString(j['status']);
    final status = switch (statusRaw?.toLowerCase()) {
      'active' => AccountStatus.active,
      'expired' => AccountStatus.expired,
      'banned' => AccountStatus.banned,
      'disabled' => AccountStatus.disabled,
      'trial' => AccountStatus.trial,
      _ => AccountStatus.unknown,
    };
    return UserInfo(
      auth: asBoolOrNull(j['auth']),
      status: status,
      statusRaw: statusRaw,
      expiresAt: asUnixTime(j['exp_date']),
      maxConnections: asInt(j['max_connections']),
      activeConnections: asInt(j['active_cons']),
      isTrial: asBool(j['is_trial']) || status == AccountStatus.trial,
      createdAt: asUnixTime(j['created_at']),
      allowedOutputFormats: asStringList(j['allowed_output_formats'])
          .map((e) => e.toLowerCase())
          .toList(),
      message: asString(j['message']),
    );
  }

  Map<String, Object?> toJson() => {
    'auth': auth,
    'status': status.name,
    'statusRaw': statusRaw,
    'expiresAt': expiresAt?.millisecondsSinceEpoch,
    'maxConnections': maxConnections,
    'activeConnections': activeConnections,
    'isTrial': isTrial,
    'createdAt': createdAt?.millisecondsSinceEpoch,
    'allowedOutputFormats': allowedOutputFormats,
  };
}

@immutable
class ServerInfo {
  const ServerInfo({
    this.url,
    this.port,
    this.httpsPort,
    this.protocol,
    this.timezone,
    this.timestampNow,
  });

  final String? url;
  final int? port;
  final int? httpsPort;
  final String? protocol;
  final String? timezone;
  final DateTime? timestampNow;

  static ServerInfo parse(Map<String, Object?> j) => ServerInfo(
    url: asString(j['url']),
    port: asInt(j['port']),
    httpsPort: asInt(j['https_port']),
    protocol: asString(j['server_protocol'])?.toLowerCase(),
    timezone: asString(j['timezone']),
    timestampNow: asUnixTime(j['timestamp_now']),
  );

  /// Server clock minus device clock (brief 5.9), for EPG "now".
  Duration? clockOffset({DateTime? deviceNow}) {
    final t = timestampNow;
    if (t == null) return null;
    return t.difference(deviceNow ?? DateTime.now().toUtc());
  }

  Map<String, Object?> toJson() => {
    'url': url,
    'port': port,
    'httpsPort': httpsPort,
    'protocol': protocol,
    'timezone': timezone,
    'timestampNow': timestampNow?.millisecondsSinceEpoch,
  };
}

@immutable
class AccountInfo {
  const AccountInfo({required this.user, this.server});

  final UserInfo user;
  final ServerInfo? server;

  /// Returns null when the body has no `user_info` object at all (e.g. `{}`),
  /// which panels send for bad logins.
  static AccountInfo? parse(Object? json) {
    final m = asMap(json);
    final ui = m['user_info'];
    if (ui is! Map || ui.isEmpty) return null;
    final si = m['server_info'];
    return AccountInfo(
      user: UserInfo.parse(asMap(ui)),
      server: si is Map ? ServerInfo.parse(asMap(si)) : null,
    );
  }
}

@immutable
class XCategory {
  const XCategory({required this.id, required this.name, this.parentId});

  final String id;
  final String name;
  final String? parentId;
}

@immutable
class XLiveStream {
  const XLiveStream({
    required this.streamId,
    required this.name,
    this.num,
    this.icon,
    this.epgChannelId,
    this.categoryId,
    this.categoryIds = const [],
    this.tvArchive = false,
    this.tvArchiveDays = 0,
    this.directSource,
    this.added,
  });

  final int streamId;
  final String name;
  final int? num;
  final String? icon;
  final String? epgChannelId;
  final String? categoryId;
  final List<String> categoryIds;
  final bool tvArchive;
  final int tvArchiveDays;
  final String? directSource;
  final DateTime? added;
}

@immutable
class XVod {
  const XVod({
    required this.streamId,
    required this.name,
    this.icon,
    this.categoryId,
    this.containerExtension = 'mp4',
    this.rating,
    this.added,
    this.directSource,
    this.year,
  });

  final int streamId;
  final String name;
  final String? icon;
  final String? categoryId;
  final String containerExtension;
  final double? rating;
  final DateTime? added;
  final String? directSource;
  final int? year;
}

@immutable
class XSeries {
  const XSeries({
    required this.seriesId,
    required this.name,
    this.cover,
    this.plot,
    this.genre,
    this.releaseDate,
    this.rating,
    this.categoryId,
    this.lastModified,
    this.backdrop,
  });

  final int seriesId;
  final String name;
  final String? cover;
  final String? plot;
  final String? genre;
  final String? releaseDate;
  final double? rating;
  final String? categoryId;
  final DateTime? lastModified;
  final String? backdrop;
}

@immutable
class XEpisode {
  const XEpisode({
    required this.id,
    required this.season,
    required this.episodeNum,
    required this.title,
    this.containerExtension = 'mp4',
    this.plot,
    this.durationSecs,
    this.image,
  });

  /// Stream id used in `/series/U/P/{id}.{ext}` (string in some panels).
  final String id;
  final int season;
  final int episodeNum;
  final String title;
  final String containerExtension;
  final String? plot;
  final int? durationSecs;
  final String? image;
}

@immutable
class XSeriesInfo {
  const XSeriesInfo({
    required this.name,
    this.plot,
    this.cover,
    this.episodesBySeason = const {},
  });

  final String name;
  final String? plot;
  final String? cover;

  /// Sorted by season number, episodes sorted by number.
  final Map<int, List<XEpisode>> episodesBySeason;
}

@immutable
class XVodInfo {
  const XVodInfo({
    required this.streamId,
    required this.name,
    this.containerExtension = 'mp4',
    this.plot,
    this.durationSecs,
    this.cover,
    this.genre,
    this.releaseDate,
  });

  final int streamId;
  final String name;
  final String containerExtension;
  final String? plot;
  final int? durationSecs;
  final String? cover;
  final String? genre;
  final String? releaseDate;
}

@immutable
class XEpgEntry {
  const XEpgEntry({
    required this.title,
    required this.start,
    required this.stop,
    this.description = '',
  });

  final String title;
  final String description;
  final DateTime start;
  final DateTime stop;
}

/// "No expiry" for null, else a short date like "9 Mar 2030".
String expiryLabel(DateTime? expiresAt) =>
    expiresAt == null ? 'No expiry' : formatDay(expiresAt);
