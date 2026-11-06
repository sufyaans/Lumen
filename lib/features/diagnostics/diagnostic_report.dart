import '../../app/app_config.dart';
import '../../core/network/connection_error.dart';
import '../../core/network/redaction.dart';
import '../../data/xtream/connection_doctor.dart';

/// Masks a host for sharing: first two characters plus the TLD
/// (brief 5.7). `provider.example.com` -> `pr***.com`,
/// `192.168.1.20` -> `19***`.
String maskHost(String host) {
  final h = host.toLowerCase();
  if (h.isEmpty) return '***';
  final first = h.length <= 2 ? h : h.substring(0, 2);
  final isIp = RegExp(r'^[\d.]+$').hasMatch(h) || h.contains(':');
  if (isIp) return '$first***';
  final dot = h.lastIndexOf('.');
  if (dot <= 0 || dot == h.length - 1) return '$first***';
  return '$first***${h.substring(dot)}';
}

/// Plain-text Connection check report. Contains no username, password,
/// tokens or stream URLs: attempts only record scheme, masked host, port,
/// user-agent profile, status and timing.
String buildDiagnosticReport({
  required String osAndDevice,
  required List<ProbeAttempt> attempts,
  ConnectionError? result,
  DateTime? at,
  Iterable<String> secrets = const [],
}) {
  final b = StringBuffer()
    ..writeln('${AppConfig.appName} connection report')
    ..writeln('App version: ${AppConfig.version}')
    ..writeln('Device: $osAndDevice')
    ..writeln('Time: ${(at ?? DateTime.now()).toUtc().toIso8601String()}')
    ..writeln(
      'Result: ${result == null ? 'OK' : '${result.kind.name} — ${result.title}'}',
    );
  if (attempts.isNotEmpty) {
    final hosts = attempts.map((a) => maskHost(a.endpoint.host)).toSet();
    b.writeln('Server: ${hosts.join(', ')}');
  }
  b.writeln('Attempts:');
  for (final (i, a) in attempts.indexed) {
    final e = a.endpoint;
    b.writeln(
      '  ${i + 1}. ${a.step} ${e.scheme}://${maskHost(e.host)}:'
      '${e.effectivePort}${e.basePath.isEmpty ? '' : ' (base path set)'} '
      'ua=${a.userAgent.id} '
      'status=${a.status ?? '-'} '
      '${a.ok ? 'ok' : a.outcome!.name} '
      '${a.elapsed.inMilliseconds} ms'
      '${a.redirectedTo == null ? '' : ' -> ${a.redirectedTo!.scheme}://${maskHost(a.redirectedTo!.host)}:${a.redirectedTo!.effectivePort}'}',
    );
  }
  if (result != null && result.details.isNotEmpty) {
    b.writeln('Details: ${_scrub(result.details, secrets)}');
  }
  return Redactor.redact(b.toString(), secrets: secrets);
}

String _scrub(String s, Iterable<String> secrets) {
  // Details may quote a URL; keep only the masked form.
  final noUrls = s.replaceAllMapped(
    RegExp(r'https?://[^\s]+'),
    (_) => '[url removed]',
  );
  return Redactor.redact(noUrls, secrets: secrets);
}
