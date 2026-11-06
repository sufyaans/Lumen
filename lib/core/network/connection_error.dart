import 'package:flutter/foundation.dart';

/// Every connection failure maps to exactly one of these (brief section 5.6).
enum ConnectionErrorKind {
  invalidInput,
  dnsFailure,
  timeoutOrRefused,
  tlsError,
  http401or403,
  http404,
  htmlResponse,
  portalUnsupported,
  authRejected,
  expired,
  disabled,
  maxConnections,
  emptyCatalog,
  malformed,
  offline,
  m3uInvalid,
}

/// A classified failure: a plain-language [title] and [body] for the UI,
/// and technical [details] for the "Details" toggle and the diagnostics
/// report. Details never contain credentials (they go through redaction).
@immutable
class ConnectionError implements Exception {
  const ConnectionError(
    this.kind, {
    this.details = '',
    this.expiredOn,
    this.maxConnections,
  });

  final ConnectionErrorKind kind;
  final String details;

  /// For [ConnectionErrorKind.expired].
  final DateTime? expiredOn;

  /// For [ConnectionErrorKind.maxConnections].
  final int? maxConnections;

  String get title => switch (kind) {
    ConnectionErrorKind.invalidInput => "That address doesn't look right",
    ConnectionErrorKind.dnsFailure => "Can't find that server",
    ConnectionErrorKind.timeoutOrRefused => "The server isn't answering",
    ConnectionErrorKind.tlsError => 'Secure connection failed',
    ConnectionErrorKind.http401or403 => 'Your provider refused the request',
    ConnectionErrorKind.http404 => "That isn't an Xtream address",
    ConnectionErrorKind.htmlResponse => 'Got a web page instead of data',
    ConnectionErrorKind.portalUnsupported => 'This looks like a portal address',
    ConnectionErrorKind.authRejected => 'Login rejected',
    ConnectionErrorKind.expired => 'Subscription expired',
    ConnectionErrorKind.disabled => 'Account disabled',
    ConnectionErrorKind.maxConnections => 'Too many devices in use',
    ConnectionErrorKind.emptyCatalog => 'Signed in, but nothing came back',
    ConnectionErrorKind.malformed => 'Unexpected response',
    ConnectionErrorKind.offline => 'No internet connection',
    ConnectionErrorKind.m3uInvalid => "That doesn't look like a playlist",
  };

  String get body => switch (kind) {
    ConnectionErrorKind.invalidInput =>
      'Enter the server address your provider gave you, for example '
          'http://example.com:8080.',
    ConnectionErrorKind.dnsFailure =>
      "Check the address for typos and that you're online. If it keeps "
          'failing, ask your provider whether the address has changed.',
    ConnectionErrorKind.timeoutOrRefused =>
      "The address was found but the server didn't respond. Check the port "
          'number, or try again in a few minutes.',
    ConnectionErrorKind.tlsError =>
      'Try http:// instead. If your provider uses a self-made certificate, '
          'you can allow it for this provider in Advanced.',
    ConnectionErrorKind.http401or403 =>
      'Your username or password may be wrong, or the provider blocked this '
          'request. Check your details. The app already tried other '
          'connection settings.',
    ConnectionErrorKind.http404 =>
      'Check the address. If your provider gave you an M3U link, use the '
          'M3U link tab.',
    ConnectionErrorKind.htmlResponse =>
      "The address leads to a website, not the provider's service. Check "
          'the address your provider gave you.',
    ConnectionErrorKind.portalUnsupported =>
      "Portal (MAG/Stalker) logins aren't supported yet. Ask your provider "
          'for an Xtream login or M3U link.',
    ConnectionErrorKind.authRejected =>
      'The server says the username or password is incorrect. Check capital '
          'letters and extra spaces.',
    ConnectionErrorKind.expired =>
      expiredOn == null
          ? 'Your subscription has ended. Renew it with your provider, then '
                'try again.'
          : 'Your subscription ended on ${formatDay(expiredOn!)}. Renew it '
                'with your provider, then try again.',
    ConnectionErrorKind.disabled =>
      'The provider has disabled or banned this account. Contact your '
          'provider.',
    ConnectionErrorKind.maxConnections =>
      maxConnections == null
          ? 'Your plan limits how many devices can watch at the same time. '
                'Stop playback on another device and try again.'
          : 'Your plan allows $maxConnections at the same time. Stop playback '
                'on another device and try again.',
    ConnectionErrorKind.emptyCatalog =>
      'The account works but returned no channels, movies or series. Try '
          'Refresh, or ask your provider.',
    ConnectionErrorKind.malformed =>
      "The server sent data we couldn't read. Run the Connection check and "
          'share the report with your provider.',
    ConnectionErrorKind.offline =>
      'Connect to a network and try again. Your saved catalog is still '
          'available.',
    ConnectionErrorKind.m3uInvalid =>
      'Choose an .m3u or .m3u8 file, or check the link.',
  };

  /// Used to pick the most useful failure when every attempt failed
  /// (brief 5.3: "401 on all attempts beats timeout on one").
  int get informativeness => switch (kind) {
    ConnectionErrorKind.authRejected => 100,
    ConnectionErrorKind.expired => 100,
    ConnectionErrorKind.disabled => 100,
    ConnectionErrorKind.maxConnections => 95,
    ConnectionErrorKind.portalUnsupported => 90,
    ConnectionErrorKind.http401or403 => 80,
    ConnectionErrorKind.htmlResponse => 70,
    ConnectionErrorKind.http404 => 60,
    ConnectionErrorKind.malformed => 55,
    ConnectionErrorKind.emptyCatalog => 50,
    ConnectionErrorKind.m3uInvalid => 50,
    ConnectionErrorKind.tlsError => 40,
    ConnectionErrorKind.timeoutOrRefused => 30,
    ConnectionErrorKind.dnsFailure => 20,
    ConnectionErrorKind.offline => 10,
    ConnectionErrorKind.invalidInput => 5,
  };

  @override
  String toString() => 'ConnectionError(${kind.name}: $details)';
}

String formatDay(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final l = d.toLocal();
  return '${l.day} ${months[l.month - 1]} ${l.year}';
}
