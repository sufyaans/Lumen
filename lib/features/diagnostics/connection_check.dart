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
    this.onWorkingUserAgent,
    this.attemptGap = const Duration(milliseconds: 400),
  }) : _ua = target.userAgent;

  final CheckTarget target;
  final NetworkClient network;

  /// Called when a different connection setting works than the saved one,
  /// so the provider can switch to it.
  final void Function(UserAgentProfile ua)? onWorkingUserAgent;
  final Duration attemptGap;
  UserAgentProfile _ua;
  final _tried = <String>[];

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
        final v4 = r.where((a) => a.type == InternetAddressType.IPv4).length;
        final v6 = r.where((a) => a.type == InternetAddressType.IPv6).length;
        final fam = [if (v4 > 0) 'IPv4', if (v6 > 0) 'IPv6'].join(' and ');
        return (
          r.isNotEmpty,
          r.isNotEmpty
              ? 'Found $fam address${r.length == 1 ? '' : 'es'}'
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
      await step(() async {
        final urls = XtreamUrls(
          target.endpoint!,
          target.username!,
          target.password!,
        );
        // Try the saved setting first, then the others, paced, stopping at
        // the first that works. A refusal with one setting and success with
        // another shows exactly what the provider filters on.
        final order = UserAgentProfile.probeOrder(saved: target.userAgent);
        String? firstReply;
        int? firstStatus;
        ConnectionError? firstError;
        for (final (i, ua) in order.indexed) {
          if (i > 0) await Future<void>.delayed(attemptGap);
          NetResponse r;
          try {
            r = await network.get(
              urls.api(),
              headers: {'User-Agent': ua.value, 'Accept': '*/*'},
            );
          } on NetException catch (e) {
            _tried.add('${ua.id}: ${e.kind.name}');
            // Transport problems don't depend on the setting.
            return (false, e.kind.name, classifyNetException(e), null);
          }
          final st = classifyStatus(r);
          final body = st == null ? decodeProviderBody(r.bytes) : null;
          if (body is JsonBody) {
            _tried.add('${ua.id}: ${r.status}');
            account = AccountInfo.parse(body.value);
            if (ua != target.userAgent) {
              _ua = ua;
              onWorkingUserAgent?.call(ua);
              return (
                true,
                'Refused with the ${target.userAgent.id} setting'
                    '${firstStatus == null ? '' : ' (HTTP $firstStatus)'}; '
                    'works with ${ua.id}. Saved for this provider.',
                null,
                r.status,
              );
            }
            return (
              true,
              'Data received (${r.bytes.length} bytes)',
              null,
              r.status,
            );
          }
          _tried.add('${ua.id}: ${r.status}');
          firstStatus ??= r.status;
          firstReply ??= replySnippet(r, secrets: _secrets);
          firstError ??=
              st ??
              switch (body) {
                HtmlBody() => const ConnectionError(
                  ConnectionErrorKind.htmlResponse,
                ),
                EmptyBody() => const ConnectionError(
                  ConnectionErrorKind.authRejected,
                ),
                _ => const ConnectionError(ConnectionErrorKind.malformed),
              };
          // Only refusals and web pages can depend on the setting.
          final k = firstError.kind;
          if (k != ConnectionErrorKind.http401or403 &&
              k != ConnectionErrorKind.htmlResponse) {
            break;
          }
        }
        return (
          false,
          'HTTP $firstStatus with every setting tried (${_tried.join(', ')})'
              '${firstReply == null ? '' : '. Server said: "$firstReply"'}',
          firstError,
          firstStatus,
        );
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
          userAgent: _ua,
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
    var headers = <String, String>{'User-Agent': _ua.value};
    if (target.endpoint != null) {
      var id = target.firstChannelId;
      if (id == null) {
        try {
          final client = XtreamClient(
            network: network,
            endpoint: target.endpoint!,
            username: target.username!,
            password: target.password!,
            userAgent: _ua,
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
    final base = target.endpoint?.basePath.isNotEmpty ?? false;
    final b = StringBuffer()
      ..writeln('${AppConfig.appName} connection check')
      ..writeln('App version: ${AppConfig.version}')
      ..writeln('Device: $osAndDevice')
      ..writeln('Time: ${DateTime.now().toUtc().toIso8601String()}')
      // Not written as a URL, so it survives the link scrubbing below.
      ..writeln(
        'Server: ${maskHost(target.host)} · port ${target.port} · '
        '${target.scheme}${base ? ' · with base path' : ''}',
      )
      ..writeln(
        'User-agent profile: ${_ua.id}'
        '${_tried.isEmpty ? '' : ' (tried: ${_tried.join(', ')})'}',
      );
    for (final (i, s) in [..._steps, _playback].indexed) {
      b.writeln(
        '${i + 1}. ${s.title}: ${s.status.name}'
        '${s.httpStatus == null ? '' : ' (HTTP ${s.httpStatus})'}'
        '${s.elapsed == null ? '' : ' ${s.elapsed!.inMilliseconds} ms'}'
        '${s.error == null ? '' : ' [${s.error!.kind.name}]'}',
      );
      if (s.detail != null && s.status != CheckStatus.pending) {
        b.writeln('   ${s.detail}');
      }
    }
    final out = b.toString().replaceAll(target.host, maskHost(target.host));
    return Redactor.redact(
      out.replaceAll(RegExp(r'https?://[^\s]+'), '[url removed]'),
      secrets: _secrets,
    );
  }
}

/// A short, readable, secret-free excerpt of an error reply, e.g. a panel's
/// "Invalid credentials" or a firewall's "Access denied".
String? replySnippet(NetResponse r, {Iterable<String> secrets = const []}) {
  if (r.bytes.isEmpty) return null;
  var t = utf8.decode(r.bytes.take(2048).toList(), allowMalformed: true);
  t = t
      .replaceAll(
        RegExp(r'<(script|style)[^>]*>[\s\S]*?</\1>', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'https?://[^\s"]+'), '[link]')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (t.isEmpty) return null;
  if (t.length > 160) t = '${t.substring(0, 160)}…';
  return Redactor.redact(t, secrets: secrets);
}

/// Template-stored M3U URLs need credentials put back for a test.
String? decodeTemplateUrl(String? url, Uri? playlist) => url == null
    ? null
    : SecretTemplate.decode(
        url,
        username: playlist?.queryParameters['username'],
        password: playlist?.queryParameters['password'],
      );
