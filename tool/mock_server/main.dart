// Starts the mock provider on http://127.0.0.1:25461 for manual testing.
// Sign in with server 127.0.0.1:25461, username "user", password "pass".
// (On an Android emulator use 10.0.2.2:25461.)

// ignore_for_file: avoid_print

import 'dart:io';

import 'mock_xtream_server.dart';
import 'test_clip.dart';

Future<void> main() async {
  // Listens on all interfaces so a phone on the same Wi-Fi can reach it.
  final server = await MockXtreamServer.start(
    MockProvider()
      ..liveStreamCount = 120
      ..videoClip = buildTestClip()
      ..categoryCount = 6
      ..categoryNames = [
        'News',
        'Sport',
        'Kids',
        'Movies',
        'Music',
        'Documentaries',
      ],
    port: 25461,
    address: InternetAddress.anyIPv4,
  );
  final ips = [
    for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4))
      for (final a in i.addresses) a.address,
  ];
  print(
    'Mock Xtream provider on port ${server.port} (username user, password pass).',
  );
  print('  Android emulator: 10.0.2.2:25461');
  for (final ip in ips) {
    print('  Same Wi-Fi:       $ip:25461');
  }
  print('Ctrl+C to stop.');
}
