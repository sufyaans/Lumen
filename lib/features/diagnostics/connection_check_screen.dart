import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/theme.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/network/connection_error.dart';
import '../../core/network/network_client.dart';
import '../../core/network/user_agents.dart';
import '../../core/platform/form_factor.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/content_row.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../data/secure/credential_store.dart';
import '../../data/xtream/server_endpoint.dart';
import '../providers/sign_in_service.dart';
import 'connection_check.dart';

/// Builds the runner for a saved provider or for details typed into the
/// sign-in form. Overridden in widget tests.
final connectionCheckRunnerProvider = FutureProvider.autoDispose
    .family<ConnectionCheckRunner?, ConnectionCheckArgs>((ref, args) async {
      final online = ref.read(connectivityOnlineProvider).value ?? true;
      if (args.providerId == null) {
        final input = ServerEndpoint.parse(args.server ?? '');
        if (!input.isValid) return null;
        final host = input.candidates.first.host;
        final net = DioNetworkClient(
          allowUntrustedCertFor: args.allowUntrustedCert
              ? (h) => h == host
              : null,
        );
        ref.onDispose(net.close);
        return LiveConnectionCheck(
          online: online,
          network: net,
          target: CheckTarget.xtream(
            endpoint: input.candidates.first,
            username: args.username ?? '',
            password: args.password ?? '',
          ),
        );
      }
      final reg = ref.read(providerRegistryProvider);
      final p = await reg.byId(args.providerId!);
      if (p == null) return null;
      final repo = ref.read(catalogRepositoryProvider);
      final counts = (
        await repo.count(p.id, ContentKind.live),
        await repo.count(p.id, ContentKind.movie),
        await repo.count(p.id, ContentKind.series),
      );
      final net = ref.read(networkForProvider)(p);
      final store = ref.read(credentialStoreProvider);
      final firstChannel = (await repo.channelsPage(
        p.id,
        limit: 1,
      )).firstOrNull;
      if (p.kind == 'xtream') {
        final pw = await store.readPassword(p.id);
        final e = ServerEndpoint.fromJson(
          p.endpointJson == null ? null : jsonDecode(p.endpointJson!),
        );
        if (e == null) return null;
        final db = ref.read(appDatabaseProvider);
        return LiveConnectionCheck(
          online: online,
          network: net,
          // A different setting worked: remember it, like sign-in does.
          onWorkingUserAgent: (ua) => unawaited(
            (db.update(db.providers)..where((t) => t.id.equals(p.id))).write(
              ProvidersCompanion(userAgentId: Value(ua.id)),
            ),
          ),
          target: CheckTarget.xtream(
            endpoint: e,
            username: p.username ?? '',
            password: pw is SecretFound ? pw.value : '',
            userAgent:
                UserAgentProfile.byId(p.userAgentId) ?? UserAgentProfile.okhttp,
            firstChannelId: int.tryParse(firstChannel?.remoteId ?? ''),
            catalogCounts: counts,
          ),
        );
      }
      final secret = await store.readSecretUrl(p.id);
      final playlist = secret is SecretFound
          ? Uri.tryParse(secret.value)
          : null;
      if (playlist == null) return null;
      Map<String, String> headers = const {};
      if (firstChannel?.headersJson != null) {
        try {
          headers = (jsonDecode(firstChannel!.headersJson!) as Map).map(
            (k, v) => MapEntry('$k', '$v'),
          );
        } catch (_) {}
      }
      return LiveConnectionCheck(
        online: online,
        network: net,
        target: CheckTarget.playlist(
          playlistUrl: playlist,
          firstStreamUrl: decodeTemplateUrl(firstChannel?.url, playlist),
          headers: headers,
          catalogCounts: counts,
        ),
      );
    });

/// Connection check (brief 5.7): each step live with pass/fail and timing,
/// Copy report, and an optional Test playback.
class ConnectionCheckScreen extends ConsumerStatefulWidget {
  const ConnectionCheckScreen({super.key, required this.args});

  final ConnectionCheckArgs args;

  @override
  ConsumerState<ConnectionCheckScreen> createState() =>
      _ConnectionCheckScreenState();
}

class _ConnectionCheckScreenState extends ConsumerState<ConnectionCheckScreen> {
  List<CheckStep> _steps = const [];
  StreamSubscription<List<CheckStep>>? _sub;
  ConnectionCheckRunner? _runner;
  bool _running = false;
  bool _testing = false;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _start(ConnectionCheckRunner runner) {
    _sub?.cancel();
    setState(() {
      _runner = runner;
      _running = true;
    });
    _sub = runner.run().listen(
      (s) => setState(() => _steps = s),
      onDone: () {
        if (mounted) setState(() => _running = false);
      },
    );
  }

  String _device() {
    final ff = ref.read(formFactorProvider).name;
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion} · $ff';
    } catch (_) {
      return ff;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(connectionCheckRunnerProvider(widget.args));
    final runner = async.value;
    if (runner != null && _runner == null && !_running) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _runner == null) _start(runner);
      });
    }
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    final g = pageGutter(context);
    final w = MediaQuery.sizeOf(context).width;
    final side = w - 2 * g > 860 ? (w - 860) / 2 : g;
    final mainSteps = _steps.isEmpty
        ? const <CheckStep>[]
        : _steps.sublist(0, _steps.length - 1);
    final playback = _steps.isEmpty ? null : _steps.last;

    return Scaffold(
      body: SafeArea(
        child: FocusMemory(
          debugLabel: 'connection-check',
          child: ListView(
            // Keep the steps a readable width on TVs and tablets.
            padding: EdgeInsets.fromLTRB(side, 16, side, 40),
            children: [
              Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back,
                    label: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Connection check', style: t.headlineMedium),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (async.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (runner == null)
                const EmptyState(
                  message: 'Enter a server address on the sign-in screen first, then run the check.',
                )
              else ...[
                for (final (i, s) in mainSteps.indexed)
                  _StepTile(index: i + 1, step: s),
                if (playback != null && playback.status != CheckStatus.skipped)
                  _StepTile(index: 7, step: playback),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    PillButton(
                      label: 'Run again',
                      icon: Icons.refresh,
                      onPressed: _running ? null : () => _start(runner),
                    ),
                    PillButton(
                      label: _testing ? 'Testing…' : 'Test playback',
                      icon: Icons.play_circle_outline,
                      onPressed: _running || _testing
                          ? null
                          : () async {
                              setState(() => _testing = true);
                              final s = await runner.testPlayback();
                              if (!mounted) return;
                              setState(() {
                                _testing = false;
                                _steps = [...mainSteps, s];
                              });
                            },
                    ),
                    PillButton(
                      label: 'Copy report',
                      icon: Icons.copy,
                      tone: PillTone.primary,
                      onPressed: _running
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await Clipboard.setData(
                                ClipboardData(
                                  text: runner.report(osAndDevice: _device()),
                                ),
                              );
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Report copied. It contains no passwords or links.',
                                  ),
                                ),
                              );
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Test playback opens one channel for a moment, which uses one of your connections.',
                  style: t.bodySmall?.copyWith(color: c.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.index, required this.step});

  final int index;
  final CheckStep step;

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    final icon = switch (step.status) {
      CheckStatus.passed => const Icon(
        Icons.check_circle,
        color: Color(0xFF18A05A),
      ),
      CheckStatus.failed => Icon(Icons.error, color: c.accent),
      CheckStatus.running => SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
      ),
      CheckStatus.skipped => Icon(Icons.remove_circle_outline, color: c.muted),
      CheckStatus.pending => Icon(Icons.radio_button_unchecked, color: c.muted),
    };
    final ConnectionError? e = step.status == CheckStatus.failed
        ? step.error
        : null;
    return Semantics(
      label: '${step.title}: ${step.status.name}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: 28, child: Center(child: icon)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('$index. ${step.title}', style: t.titleSmall),
                ),
                if (step.elapsed != null)
                  Text(
                    '${step.elapsed!.inMilliseconds} ms',
                    style: t.bodySmall,
                  ),
              ],
            ),
            if (step.detail != null)
              Padding(
                padding: const EdgeInsets.only(left: 38, top: 4),
                child: Text(step.detail!, style: t.bodySmall),
              ),
            if (e != null)
              Padding(
                padding: const EdgeInsets.only(left: 38, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: t.bodyMedium?.copyWith(
                        color: c.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(e.body, style: t.bodyMedium),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
