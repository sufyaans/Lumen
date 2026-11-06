import 'dart:async';
import 'dart:math';

import 'network_client.dart';

/// Retry policy for idempotent GETs (brief section 5.9).
///
/// * Network errors and timeouts: 3 attempts total, waiting 0.5 s, 1.5 s
///   (and 4 s if more attempts are configured), each with up to 20 % jitter.
/// * 429 and 503: honour `Retry-After` (seconds or HTTP date), capped.
/// * Never retries cancellation, TLS, DNS or HTTP auth failures.
class RetryPolicy {
  const RetryPolicy({
    this.delays = const [
      Duration(milliseconds: 500),
      Duration(milliseconds: 1500),
      Duration(seconds: 4),
    ],
    this.maxAttempts = 3,
    this.maxRetryAfter = const Duration(seconds: 30),
    this.jitter = 0.2,
  });

  final List<Duration> delays;
  final int maxAttempts;
  final Duration maxRetryAfter;
  final double jitter;

  static const none = RetryPolicy(maxAttempts: 1);

  Duration delayFor(int attempt, Random random) {
    final base = delays[min(attempt, delays.length - 1)];
    final j = 1 + (random.nextDouble() * 2 - 1) * jitter;
    return base * j;
  }

  static bool isRetryableError(Object e) =>
      e is NetException &&
      (e.kind == NetFailureKind.timeout ||
          e.kind == NetFailureKind.refused ||
          e.kind == NetFailureKind.closed ||
          e.kind == NetFailureKind.offline ||
          e.kind == NetFailureKind.unknown);

  /// Parses `Retry-After` as delta-seconds or an HTTP date.
  static Duration? parseRetryAfter(String? value, {DateTime? now}) {
    if (value == null) return null;
    final v = value.trim();
    final secs = int.tryParse(v);
    if (secs != null) return secs < 0 ? null : Duration(seconds: secs);
    try {
      final at = HttpDateParser.parse(v);
      final d = at.difference(now ?? DateTime.now());
      return d.isNegative ? Duration.zero : d;
    } catch (_) {
      return null;
    }
  }
}

/// Minimal RFC 1123 date parser ("Wed, 21 Oct 2015 07:28:00 GMT").
abstract final class HttpDateParser {
  static const _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  static DateTime parse(String s) {
    final m = RegExp(
      r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})',
    ).firstMatch(s);
    if (m == null) throw FormatException('Not an HTTP date', s);
    final month = _months[m[2]!.toLowerCase()];
    if (month == null) throw FormatException('Bad month', s);
    return DateTime.utc(
      int.parse(m[3]!),
      month,
      int.parse(m[1]!),
      int.parse(m[4]!),
      int.parse(m[5]!),
      int.parse(m[6]!),
    );
  }
}

/// Runs [request] with [policy]. Retries transport errors that
/// [RetryPolicy.isRetryableError] allows, and 429/503 responses.
Future<NetResponse> getWithRetry(
  Future<NetResponse> Function() request, {
  RetryPolicy policy = const RetryPolicy(),
  CancelSignal? cancel,
  Future<void> Function(Duration)? sleep,
  Random? random,
}) async {
  final rnd = random ?? Random();
  final wait = sleep ?? _cancellableSleep(cancel);
  for (var attempt = 0; ; attempt++) {
    final last = attempt >= policy.maxAttempts - 1;
    try {
      final res = await request();
      if ((res.status == 429 || res.status == 503) && !last) {
        final ra = RetryPolicy.parseRetryAfter(res.header('retry-after'));
        var d = ra ?? policy.delayFor(attempt, rnd);
        if (d > policy.maxRetryAfter) return res;
        if (d < Duration.zero) d = Duration.zero;
        await wait(d);
        _throwIfCancelled(cancel);
        continue;
      }
      return res;
    } on NetException catch (e) {
      if (e.kind == NetFailureKind.cancelled) rethrow;
      if (last || !RetryPolicy.isRetryableError(e)) rethrow;
      await wait(policy.delayFor(attempt, rnd));
      _throwIfCancelled(cancel);
    }
  }
}

void _throwIfCancelled(CancelSignal? c) {
  if (c?.isCancelled ?? false) {
    throw NetException(NetFailureKind.cancelled, 'cancelled');
  }
}

Future<void> Function(Duration) _cancellableSleep(CancelSignal? cancel) => (d) {
  if (cancel == null) return Future<void>.delayed(d);
  return Future.any([Future<void>.delayed(d), cancel.whenCancelled]);
};
