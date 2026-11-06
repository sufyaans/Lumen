// Starts the mock provider on http://127.0.0.1:25461 for manual testing.
// Sign in with server 127.0.0.1:25461, username "user", password "pass".
// (On an Android emulator use 10.0.2.2:25461.)

// ignore_for_file: avoid_print

import 'mock_xtream_server.dart';

Future<void> main() async {
  final server = await MockXtreamServer.start(MockProvider(), port: 25461);
  print(
    'Mock Xtream provider on ${server.base} (user / pass). Ctrl+C to stop.',
  );
}
