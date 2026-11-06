import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/core/network/connection_error.dart';
import 'package:lumen/core/network/network_client.dart';
import 'package:lumen/core/network/user_agents.dart';
import 'package:lumen/data/xtream/server_endpoint.dart';
import 'package:lumen/features/diagnostics/connection_check.dart';

import '../../tool/mock_server/mock_xtream_server.dart';

void main() {
  late MockXtreamServer server;
  final net = DioNetworkClient();
  tearDownAll(net.close);
  tearDown(() => server.close());

  Future<(List<CheckStep>, LiveConnectionCheck, List<UserAgentProfile>)>
  runCheck(MockProvider p, {String pass = 'pass'}) async {
    server = await MockXtreamServer.start(p);
    final saved = <UserAgentProfile>[];
    final check = LiveConnectionCheck(
      network: net,
      attemptGap: Duration.zero,
      onWorkingUserAgent: saved.add,
      target: CheckTarget.xtream(
        endpoint: ServerEndpoint.parse('${server.base}').candidates.first,
        username: 'user',
        password: pass,
      ),
    );
    final steps = await check.run().last;
    return (steps, check, saved);
  }

  test(
    'refused with okhttp but fine as a browser: passes and saves it',
    () async {
      final (steps, check, saved) = await runCheck(
        MockProvider()..requireUserAgent = RegExp(r'^Mozilla/'),
      );
      expect(steps[3].status, CheckStatus.passed);
      expect(steps[3].detail, contains('works with browser'));
      expect(steps[4].status, CheckStatus.passed);
      expect(
        steps[5].status,
        CheckStatus.passed,
        reason: 'catalogue uses the working setting',
      );
      expect(saved, [UserAgentProfile.browser]);
      expect(
        check.report(osAndDevice: 'test'),
        contains('User-agent profile: browser'),
      );
    },
  );

  test('512 with every setting: says so, quotes the reply, report keeps scheme and port', () async {
    final (steps, check, saved) = await runCheck(
      MockProvider()..loginStatus = 512,
      pass: 'S3cr3t!',
    );
    expect(steps[3].status, CheckStatus.failed);
    expect(steps[3].error!.kind, ConnectionErrorKind.http401or403);
    expect(steps[3].detail, contains('every setting tried'));
    expect(steps[3].detail, contains('Server said: "error 512"'));
    expect(saved, isEmpty);
    final report = check.report(osAndDevice: 'test');
    expect(report, contains('Server: 12*** · port ${server.port} · http'));
    expect(report, contains('okhttp: 512'));
    expect(report, contains('browser: 512'));
    expect(report, isNot(contains('S3cr3t!')));
    expect(report, isNot(contains('[url removed]')));
  });

  test('address families are reported', () async {
    final (steps, _, _) = await runCheck(MockProvider());
    expect(steps[1].detail, contains('IP address'));
  });
}
