import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network/connection_error.dart';
import '../../core/network/network_client.dart';
import '../../core/network/redaction.dart';
import '../../core/network/retry.dart';
import '../../core/network/user_agents.dart';
import '../../core/utils/text_clean.dart';
import 'server_endpoint.dart';
import 'stream_urls.dart';
import 'tolerant_json.dart';
import 'xtream_client.dart';
import 'xtream_models.dart';

/// One request made during a probe, for the diagnostics report. Contains
/// no credentials: the URL is never stored, only scheme/host/port.
@immutable
class ProbeAttempt {
  const ProbeAttempt({
    required this.endpoint,
    required this.userAgent,
    required this.step,
    required this.elapsed,
    this.status,
    this.outcome,
    this.redirectedTo,
  });

  final ServerEndpoint endpoint;
  final UserAgentProfile userAgent;

  /// `login` or `catalog`.
  final String step;
  final Duration elapsed;
  final int? status;

  /// null = success, otherwise the error class.
  final ConnectionErrorKind? outcome;
  final ServerEndpoint? redirectedTo;

  bool get ok => outcome == null;
}

enum ProbeWarning {
  /// Auth passed but `get_live_categories` failed; provider saved anyway.
  catalogUnreachable,

  /// `active_cons` >= `max_connections`.
  atConnectionLimit,

  /// Credentials have inner spaces; tried as typed.
  credentialsHaveSpaces,
}

/// The working profile to persist on the provider record (brief 5.3 step 6).
@immutable
class WorkingProfile {
  const WorkingProfile({required this.endpoint, required this.userAgent});

  final ServerEndpoint endpoint;
  final UserAgentProfile userAgent;
}

sealed class ProbeResult {
  const ProbeResult(this.attempts);
  final List<ProbeAttempt> attempts;
}

class ProbeSuccess extends ProbeResult {
  const ProbeSuccess({
    required this.profile,
    required this.account,
    required this.username,
    required this.password,
    this.liveCategoryCount,
    this.warnings = const {},
    required List<ProbeAttempt> attempts,
  }) : super(attempts);

  final WorkingProfile profile;
  final AccountInfo account;

  /// Cleaned credentials that worked (store in secure storage only).
  final String username;
  final String password;
  final int? liveCategoryCount;
  final Set<ProbeWarning> warnings;
}

class ProbeFailure extends ProbeResult {
  const ProbeFailure(
    this.error, {
    this.account,
    required List<ProbeAttempt> attempts,
  }) : super(attempts);

  final ConnectionError error;

  /// Present for expired/disabled accounts so the UI can show details.
  final AccountInfo? account;
}

/// Signs in to an Xtream provider the way a patient human would: tries the
/// address as typed, the other scheme, and player-like user-agents, one at
/// a time, and stops at the first success (brief 5.3).
///
/// * Sequential, never parallel; total time bounded by [budget].
/// * Transport failures (DNS, refused, timeout, TLS) skip the remaining
///   user-agents for that endpoint: the agent can't fix a dead socket.
/// * 401/403 and HTML challenge pages try the next user-agent.
/// * A clear "wrong login" stops immediately.
/// * Never opens a stream (that would use a connection slot).
class ConnectionDoctor {
  ConnectionDoctor({
    required this.network,
    this.timeouts = const NetTimeouts(),
    this.budget = const Duration(seconds: 40),
    this.clock,
  });

  final NetworkClient network;
  final NetTimeouts timeouts;
  final Duration budget;
  final DateTime Function()? clock;

  DateTime _now() => clock?.call() ?? DateTime.now();

  Future<ProbeResult> probe({
    required ServerInput input,
    required String username,
    required String password,
    WorkingProfile? saved,
    CancelSignal? cancel,
    void Function(ProbeAttempt attempt)? onAttempt,
  }) async {
    final attempts = <ProbeAttempt>[];
    void log(ProbeAttempt a) {
      attempts.add(a);
      onAttempt?.call(a);
    }

    if (!input.isValid) {
      return ProbeFailure(
        input.error ?? const ConnectionError(ConnectionErrorKind.invalidInput),
        attempts: attempts,
      );
    }
    final user = cleanCredential(username);
    final pass = cleanCredential(password);
    final warnings = <ProbeWarning>{
      if (hasInnerWhitespace(user) || hasInnerWhitespace(pass))
        ProbeWarning.credentialsHaveSpaces,
    };
    if (user.isEmpty || pass.isEmpty) {
      return ProbeFailure(
        const ConnectionError(
          ConnectionErrorKind.authRejected,
          details: 'username or password is empty',
        ),
        attempts: attempts,
      );
    }

    final candidates = <ServerEndpoint>[
      if (saved != null) saved.endpoint,
      for (final c in input.candidates)
        if (c != saved?.endpoint) c,
    ];
    final agents = UserAgentProfile.probeOrder(saved: saved?.userAgent);
    final deadline = _now().add(budget);

    ConnectionError? best;
    AccountInfo? bestAccount;
    void consider(ConnectionError e, {AccountInfo? account}) {
      if (best == null || e.informativeness > best!.informativeness) {
        best = e;
        bestAccount = account;
      }
    }

    for (final endpoint in candidates) {
      agentLoop:
      for (final ua in agents) {
        if (cancel?.isCancelled ?? false) {
          return ProbeFailure(
            const ConnectionError(
              ConnectionErrorKind.timeoutOrRefused,
              details: 'cancelled',
            ),
            attempts: attempts,
          );
        }
        if (_now().isAfter(deadline)) break;

        final urls = XtreamUrls(endpoint, user, pass);
        final started = _now();
        NetResponse res;
        try {
          res = await getWithRetry(
            () => network.get(
              urls.api(),
              headers: {'User-Agent': ua.value, 'Accept': '*/*'},
              timeouts: timeouts,
              cancel: cancel,
            ),
            // Respect Retry-After on 429/503 once; no blind retries here,
            // the probe itself is the retry loop.
            policy: const RetryPolicy(maxAttempts: 2),
            cancel: cancel,
          );
        } on NetException catch (e) {
          final err = classifyNetException(e);
          log(
            ProbeAttempt(
              endpoint: endpoint,
              userAgent: ua,
              step: 'login',
              elapsed: _now().difference(started),
              outcome: err.kind,
            ),
          );
          if (e.kind == NetFailureKind.cancelled) {
            return ProbeFailure(err, attempts: attempts);
          }
          consider(err);
          // Transport problems don't depend on the user-agent.
          break agentLoop;
        }

        final finalEndpoint = res.redirects.isEmpty
            ? endpoint
            : ServerEndpoint.fromApiUrl(res.finalUrl);
        final moved = finalEndpoint != endpoint ? finalEndpoint : null;

        ConnectionError? err = classifyStatus(res);
        AccountInfo? account;
        if (err == null) {
          final body = decodeProviderBody(res.bytes);
          switch (body) {
            case JsonBody(:final value):
              account = AccountInfo.parse(value);
              err = _classifyAccount(account);
            case HtmlBody(:final snippet):
              err = ConnectionError(
                ConnectionErrorKind.htmlResponse,
                details: 'HTML: $snippet',
              );
            case EmptyBody():
              err = const ConnectionError(
                ConnectionErrorKind.authRejected,
                details: 'empty response',
              );
            case MalformedBody(:final detail):
              err = ConnectionError(
                ConnectionErrorKind.malformed,
                details: detail,
              );
          }
        }

        if (err != null &&
            input.looksLikePortal &&
            (err.kind == ConnectionErrorKind.http404 ||
                err.kind == ConnectionErrorKind.htmlResponse ||
                err.kind == ConnectionErrorKind.malformed)) {
          err = ConnectionError(
            ConnectionErrorKind.portalUnsupported,
            details: err.details,
          );
        }

        log(
          ProbeAttempt(
            endpoint: endpoint,
            userAgent: ua,
            step: 'login',
            elapsed: _now().difference(started),
            status: res.status,
            outcome: err?.kind,
            redirectedTo: moved,
          ),
        );

        if (err == null) {
          final working = WorkingProfile(
            endpoint: finalEndpoint,
            userAgent: ua,
          );
          final cats = await _checkCatalog(
            working,
            user,
            pass,
            cancel: cancel,
            log: log,
          );
          return ProbeSuccess(
            profile: working,
            account: account!,
            username: user,
            password: pass,
            liveCategoryCount: cats,
            warnings: {
              ...warnings,
              if (cats == null) ProbeWarning.catalogUnreachable,
              if (account.user.atConnectionLimit)
                ProbeWarning.atConnectionLimit,
            },
            attempts: attempts,
          );
        }

        consider(err, account: account);
        switch (err.kind) {
          // Definitive answers from a working server: stop everything.
          case ConnectionErrorKind.authRejected:
          case ConnectionErrorKind.expired:
          case ConnectionErrorKind.disabled:
          case ConnectionErrorKind.portalUnsupported:
            return ProbeFailure(err, account: account, attempts: attempts);
          // The agent may matter: try the next one.
          case ConnectionErrorKind.http401or403:
          case ConnectionErrorKind.htmlResponse:
            continue agentLoop;
          // Wrong address for this endpoint; next candidate.
          default:
            break agentLoop;
        }
      }
    }

    return ProbeFailure(
      best ?? const ConnectionError(ConnectionErrorKind.timeoutOrRefused),
      account: bestAccount,
      attempts: attempts,
    );
  }

  ConnectionError? _classifyAccount(AccountInfo? a) {
    if (a == null) {
      return const ConnectionError(
        ConnectionErrorKind.authRejected,
        details: 'no user_info in response',
      );
    }
    final u = a.user;
    if (u.auth == false) {
      return const ConnectionError(
        ConnectionErrorKind.authRejected,
        details: 'auth=0',
      );
    }
    if (u.status == AccountStatus.banned ||
        u.status == AccountStatus.disabled) {
      return ConnectionError(
        ConnectionErrorKind.disabled,
        details: 'status=${u.statusRaw}',
      );
    }
    final exp = u.expiresAt;
    final now = (clock?.call() ?? DateTime.now()).toUtc();
    if (u.status == AccountStatus.expired ||
        (exp != null && exp.isBefore(now))) {
      return ConnectionError(
        ConnectionErrorKind.expired,
        expiredOn: exp,
        details: 'status=${u.statusRaw}, exp=${exp?.toIso8601String()}',
      );
    }
    if (u.auth == null && u.status == AccountStatus.unknown) {
      return const ConnectionError(
        ConnectionErrorKind.authRejected,
        details: 'no auth and no status',
      );
    }
    return null;
  }

  /// Step 4: `get_live_categories`. Returns the count, or null on failure.
  Future<int?> _checkCatalog(
    WorkingProfile p,
    String user,
    String pass, {
    CancelSignal? cancel,
    required void Function(ProbeAttempt) log,
  }) async {
    final started = _now();
    final client = XtreamClient(
      network: network,
      endpoint: p.endpoint,
      username: user,
      password: pass,
      userAgent: p.userAgent,
      timeouts: timeouts,
      retry: const RetryPolicy(maxAttempts: 2),
    );
    try {
      final cats = await client.liveCategories(cancel: cancel);
      log(
        ProbeAttempt(
          endpoint: p.endpoint,
          userAgent: p.userAgent,
          step: 'catalog',
          elapsed: _now().difference(started),
          status: 200,
        ),
      );
      return cats.length;
    } on ConnectionError catch (e) {
      NetLog.w('catalog check failed: ${e.details}');
      log(
        ProbeAttempt(
          endpoint: p.endpoint,
          userAgent: p.userAgent,
          step: 'catalog',
          elapsed: _now().difference(started),
          outcome: e.kind,
        ),
      );
      return null;
    }
  }
}
