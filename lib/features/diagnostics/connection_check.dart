import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../app/app_config.dart';
import '../../core/network/connection_error.dart';
import '../../core/network/network_client.dart';
import '../../core/network/redaction.dart';
import '../../core/network/user_agents.dart';
import '../../data/db/secret_template.dart';
import '../../data/xtream/server_endpoint.dart';
import '../../data/xtream/stream_probe.dart';
import '../../data/xtream/stream_urls.dart';
import '../../data/xtream/tolerant_json.dart';
import '../../data/xtream/xtream_client.dart';
import '../../data/xtream/xtream_models.dart';
import 'diagnostic_report.dart';

enum CheckStatus { pending, running, passed, failed, skipped }

@immutable
class CheckStep {
  const CheckStep(
    this.title, {
    this.status = CheckStatus.pending,
    this.detail,
    this.elapsed,
    this.error,
    this.httpStatus,
  });

  final String title;
  final CheckStatus status;
  final String? detail;
  final Duration? elapsed;
  final ConnectionError? error;
  final int? httpStatus;

  CheckStep copyWith({
    CheckStatus? status,
    String? detail,
    Duration? elapsed,
    ConnectionError? error,
    int? httpStatus,
  }) => CheckStep(
    title,
    status: status ?? this.status,
    detail: detail ?? this.detail,
    elapsed: elapsed ?? this.elapsed,
    error: error ?? this.error,
    httpStatus: httpStatus ?? this.httpStatus,
  );
}

/// Runs the step-by-step diagnostic (brief 5.7). Faked in widget tests.
abstract interface class ConnectionCheckRunner {
  /// Emits the full step list each time a step changes.
  Stream<List<CheckStep>> run();

  /// Optional step 7. Opens one live stream briefly (uses a connection
  /// slot, so only on request).
  Future<CheckStep> testPlayback();

  /// Plain-text report: no username, password, tokens or stream URLs.
  String report({required String osAndDevice});
}

/// What the check needs to know about the target.
@immutable
class CheckTarget {
  const CheckTarget.xtream({
    required this.endpoint,
    required this.username,
    required this.password,
    this.userAgent = UserAgentProfile.okhttp,
    this.firstChannelId,
    this.catalogCounts,
  }) : playlistUrl = null,
       firstStreamUrl = null,
       headers = const {};

  const CheckTarget.playlist({
    required Uri this.playlistUrl,
    this.firstStreamUrl,
    this.headers = const {},
    this.catalogCounts,
  }) : endpoint = null,
       username = null,
       password = null,
       userAgent = UserAgentProfile.vlc,
       firstChannelId = null;

  final ServerEndpoint? endpoint;
  final String? username;
  final String? password;
  final UserAgentProfile userAgent;
  final int? firstChannelId;
  final Uri? playlistUrl;
  final String? firstStreamUrl;
  final Map<String, String> headers;

  /// From the local database: (channels, movies, series).
  final (int, int, int)? catalogCounts;

  String get host => endpoint?.host ?? playlistUrl!.host;
  int get port =>
      endpoint?.effectivePort ??
      (playlistUrl!.hasPort
          ? playlistUrl!.port
          : (playlistUrl!.scheme == 'https' ? 443 : 80));
  String get scheme => endpoint?.scheme ?? playlistUrl!.scheme;
}

class LiveConnectionCheck implements ConnectionCheckRunner {
  LiveConnectionCheck({
    required this.target,
    required this.network,
    this.online = true,
  });

  final CheckTarget target;
  final NetworkClient network;

  /// Connectivity hint at the time the check starts.
  final bool online;

  final _steps = <CheckStep>[
    const CheckStep('Network reachable'),
    const CheckStep('Address resolved'),
    const CheckStep('Server connected'),
    const CheckStep('Response readable'),
    const CheckStep('Login accepted'),
    const CheckStep('Catalogue reachable'),
  ];
  CheckStep _playback = const CheckStep(
    'Test playback',
    status: CheckStatus.skipped,
    detail: 'Not run',
  );

  List<String> get _secrets => [
    ?target.username,
    ?target.password,
    if (target.playlistUrl != null) target.playlistUrl!.query,
  ];

  @override
  Stream<List<CheckStep>> run() async* {
    final c = StreamController<List<CheckStep>>();
    unawaited(_run(c));
    yield* c.stream;
  }

  Future<void> _run(StreamController<List<CheckStep>> out) async {
    var i = 0;
    var stop = false;
    void emit() => out.add(List.unmodifiable([..._steps, _playback]));

    Future<void> step(
      Future<(bool, String?, ConnectionError?, int?)> Function() body,
    ) async {
      if (stop) {
        _steps[i] = _steps[i].copyWith(
          status: CheckStatus.skipped,
          detail: 'Skipped',
        );
        i++;
        emit();
        return;
      }
      _steps[i] = _steps[i].copyWith(status: CheckStatus.running);
      emit();
      final sw = Stopwatch()..start();
      try {
        final (ok, detail, err, status) = await body();
        _steps[i] = _steps[i].copyWith(
          status: ok ? CheckStatus.passed : CheckStatus.failed,
          detail: detail,
          error: err,
          elapsed: sw.elapsed,
          httpStatus: status,
        );
        if (!ok) stop = true;
      } catch (e) {
        _steps[i] = _steps[i].copyWith(
          status: CheckStatus.failed,
          detail: Redactor.redact('$e', secrets: _secrets),
          error: const ConnectionError(ConnectionErrorKind.malformed),
          elapsed: sw.elapsed,
        );
        stop = true;
      }
      i++;
      emit();
    }

    emit();
    // 1. Network reachable (connectivity is only a hint).
    await step(
      () async => online
          ? (true, 'Connected to a network', null, null)
          : (
              false,
              'No network connection',
              const ConnectionError(ConnectionErrorKind.offline),
              null,
            ),
    );

    // 2. Address resolved.
    await step(() async {
      final h = target.host;
      if (InternetAddress.tryParse(h) != null) {
        return (true, 'IP address, no lookup needed', null, null);
      }
      try {
        final r = await InternetAddress.lookup(h)
            .timeout(const Duration(seconds: 10));
        return (
          r.isNotEmpty,
          r.isNotEmpty
              ? 'Found ${r.length} address${r.length == 1 ? '' : 'es'}'
              : 'No address',
          r.isEmpty
              ? const ConnectionError(ConnectionErrorKind.dnsFailure)
              : null,
          null,
        );
      } catch (_) {
        return (
          false,
          'The name could not be found',
          const ConnectionError(ConnectionErrorKind.dnsFailure),
          null,
        );
      }
    });

    // 3. Server connected (TCP only).
    await step(() async {
      try {
        final s = await Socket.connect(
          target.host,
          target.port,
          timeout: const Duration(seconds: 10),
        );
        s.destroy();
        return (true, 'Port ${target.port} is open', null, null);
      } catch (_) {
        return (
          false,
          'Port ${target.port} did not answer',
          const ConnectionError(ConnectionErrorKind.timeoutOrRefused),
          null,
        );
      }
    });

    // 4 + 5. Response readable, login accepted.
    AccountInfo? account;
    if (target.endpoint != null) {
      NetResponse? res;
      await step(() async {
        final urls = XtreamUrls(
          target.endpoint!,
          target.username!,
          target.password!,
        );
        try {
          res = await network.get(
            urls.api(),
            headers: {'User-Agent': target.userAgent.value, 'Accept': '*/*'},
          );
        } on NetException catch (e) {
          return (false, e.kind.name, classifyNetException(e), null);
        }
        final r = res!;
        final st = classifyStatus(r);
        if (st != null) return (false, 'HTTP ${r.status}', st, r.status);
        final body = decodeProviderBody(r.bytes);
        return switch (body) {
          JsonBody(:final value) => () {
            account = AccountInfo.parse(value);
            return (
              true,
              'Data received (${r.bytes.length} bytes)',
              null,
              r.status,
            );
          }(),
          HtmlBody() => (
            false,
            'A web page came back',
            const ConnectionError(ConnectionErrorKind.htmlResponse),
            r.status,
          ),
          EmptyBody() => (
            false,
            'Empty response',
            const ConnectionError(ConnectionErrorKind.authRejected),
            r.status,
          ),
          MalformedBody() => (
            false,
            'Unreadable data',
            const ConnectionError(ConnectionErrorKind.malformed),
            r.status,
          ),
        };
      });
      await step(() async {
        final a = account;
        if (a == null || a.user.auth == false) {
          return (
            false,
            'The server rejected the login',
            const ConnectionError(ConnectionErrorKind.authRejected),
            null,
          );
        }
        final u = a.user;
        if (u.status == AccountStatus.banned ||
            u.status == AccountStatus.disabled) {
          return (
            false,
            'Account ${u.statusRaw}',
            const ConnectionError(ConnectionErrorKind.disabled),
            null,
          );
        }
        final exp = u.expiresAt;
        if (u.status == AccountStatus.expired ||
            (exp != null && exp.isBefore(DateTime.now().toUtc()))) {
          return (
            false,
            'Expired',
            ConnectionError(ConnectionErrorKind.expired, expiredOn: exp),
            null,
          );
        }
        final cons = u.maxConnections == null
            ? ''
            : ' · ${u.activeConnections ?? 0} of ${u.maxConnections} connections in use';
        return (
          true,
          '${u.statusRaw ?? 'Active'} · ${expiryLabel(exp)}$cons',
          null,
          null,
        );
      });
      await step(() async {
        final client = XtreamClient(
          network: network,
          endpoint: target.endpoint!,
          username: target.username!,
          password: target.password!,
          userAgent: target.userAgent,
        );
        try {
          final cats = await client.liveCategories();
          final counts = target.catalogCounts;
          return (
            true,
            '${cats.length} live categories'
                '${counts == null ? '' : ' · saved: ${counts.$1} channels, ${counts.$2} movies, ${counts.$3} series'}',
            null,
            200,
          );
        } on ConnectionError catch (e) {
          return (false, e.kind.name, e, null);
        }
      });
    } else {
      // Playlist: download the start of it and check it's a playlist.
      await step(() async {
        try {
          final r = await network.get(
            target.playlistUrl!,
            headers: {'User-Agent': target.userAgent.value},
            maxBytes: 64 * 1024,
          );
          final st = classifyStatus(r);
          if (st != null) return (false, 'HTTP ${r.status}', st, r.status);
          final head = utf8
              .decode(r.bytes.take(4096).toList(), allowMalformed: true)
              .trimLeft();
          final okPlaylist =
              head.toUpperCase().startsWith('#EXTM3U') ||
              head.contains('#EXTINF');
          return okPlaylist
              ? (true, 'Playlist received', null, r.status)
              : (
                  false,
                  'Not a playlist',
                  const ConnectionError(ConnectionErrorKind.m3uInvalid),
                  r.status,
                );
        } on NetException catch (e) {
          return (false, e.kind.name, classifyNetException(e), null);
        }
      });
      _steps[i] = _steps[i].copyWith(
        status: CheckStatus.skipped,
        detail: 'Not used for playlists',
      );
      i++;
      emit();
      await step(() async {
        final counts = target.catalogCounts;
        return (
          true,
          counts == null
              ? 'Playlist readable'
              : 'Saved: ${counts.$1} channels, ${counts.$2} movies, ${counts.$3} series',
          null,
          null,
        );
      });
    }
    await out.close();
  }

  @override
  Future<CheckStep> testPlayback() async {
    final sw = Stopwatch()..start();
    Uri? url;
    var headers = <String, String>{'User-Agent': target.userAgent.value};
    if (target.endpoint != null) {
      var id = target.firstChannelId;
      if (id == null) {
        try {
          final client = XtreamClient(
            network: network,
            endpoint: target.endpoint!,
            username: target.username!,
            password: target.password!,
            userAgent: target.userAgent,
          );
          final cats = await client.liveCategories();
          if (cats.isNotEmpty) {
            final r = await client.action(
              'get_live_streams',
              params: {'category_id': cats.first.id},
            );
            final first = asList(r).map(asMap).firstOrNull;
            id = asInt(first?['stream_id']);
          }
        } on ConnectionError {
          id = null;
        }
      }
      if (id != null) {
        url = XtreamUrls(
          target.endpoint!,
          target.username!,
          target.password!,
        ).live(id);
      }
    } else if (target.firstStreamUrl != null) {
      url = Uri.tryParse(target.firstStreamUrl!);
      headers = {...headers, ...target.headers};
    }
    if (url == null) {
      return _playback = const CheckStep(
        'Test playback',
        status: CheckStatus.failed,
        detail: 'No channel to test',
        error: ConnectionError(ConnectionErrorKind.emptyCatalog),
      );
    }
    final r = await checkStream(network, url, headers: headers);
    return _playback = CheckStep(
      'Test playback',
      status: r.ok ? CheckStatus.passed : CheckStatus.failed,
      detail: r.ok
          ? 'Stream started (${r.bytesRead} bytes received)'
          : r.error!.kind.name,
      error: r.error,
      elapsed: sw.elapsed,
    );
  }

  @override
  String report({required String osAndDevice}) {
    final b = StringBuffer()
      ..writeln('${AppConfig.appName} connection check')
      ..writeln('App version: ${AppConfig.version}')
      ..writeln('Device: $osAndDevice')
      ..writeln('Time: ${DateTime.now().toUtc().toIso8601String()}')
      ..writeln(
        'Server: ${target.scheme}://${maskHost(target.host)}:${target.port}',
      )
      ..writeln('User-agent profile: ${target.userAgent.id}');
    for (final (i, s) in [..._steps, _playback].indexed) {
      b.writeln(
        '${i + 1}. ${s.title}: ${s.status.name}'
        '${s.httpStatus == null ? '' : ' (HTTP ${s.httpStatus})'}'
        '${s.elapsed == null ? '' : ' ${s.elapsed!.inMilliseconds} ms'}'
        '${s.error == null ? '' : ' [${s.error!.kind.name}]'}',
      );
    }
    final out = b.toString().replaceAll(target.host, maskHost(target.host));
    return Redactor.redact(
      out.replaceAll(RegExp(r'https?://[^\s]+'), '[url removed]'),
      secrets: _secrets,
    );
  }
}

/// Template-stored M3U URLs need credentials put back for a test.
String? decodeTemplateUrl(String? url, Uri? playlist) => url == null
    ? null
    : SecretTemplate.decode(
        url,
        username: playlist?.queryParameters['username'],
        password: playlist?.queryParameters['password'],
      );
