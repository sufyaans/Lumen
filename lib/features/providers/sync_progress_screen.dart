import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/theme.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/network/connection_error.dart';
import '../../core/widgets/buttons.dart';
import '../../data/sync/catalog_sync.dart';
import '../common/error_panel.dart';
import 'password_prompt.dart';
import 'sign_in_service.dart';

const _steps = [
  (SyncStep.signingIn, 'Signing in'),
  (SyncStep.categories, 'Loading categories'),
  (SyncStep.channels, 'Loading channels'),
  (SyncStep.movies, 'Loading movies'),
  (SyncStep.series, 'Loading series'),
  (SyncStep.guide, 'Loading TV guide'),
];

String _mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

/// First sync after sign-in (brief section 6). Browsing can start as soon
/// as categories and channels are in; movies, series and the guide keep
/// loading in the background.
class SyncProgressScreen extends ConsumerWidget {
  const SyncProgressScreen({super.key, required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(syncControllerProvider);
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    final current = s.progress?.step;
    final r = s.running ? null : s.lastResult;
    final failed = r != null && !r.ok;
    final done = r != null && r.ok;
    final currentIndex = current == null
        ? -1
        : SyncStep.values.indexOf(current);
    final canBrowse = done || currentIndex > SyncStep.channels.index;

    ref.listen(syncControllerProvider, (prev, next) {
      final res = next.running ? null : next.lastResult;
      if (res != null && res.ok && context.mounted) context.go('/home');
    });

    Future<void> retry() =>
        ref.read(syncControllerProvider.notifier).refresh(providerId);

    Future<void> changeDetails() async {
      // A provider that never finished a first sync is removed again.
      final reg = ref.read(providerRegistryProvider);
      final p = await reg.byId(providerId);
      if (p != null && p.lastSyncAt == null) await reg.remove(providerId);
      if (context.mounted) context.go('/add-provider');
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: FocusMemory(
            debugLabel: 'sync',
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        failed
                            ? "Couldn't finish loading"
                            : 'Getting your channels ready',
                        style: t.headlineMedium,
                      ),
                      const SizedBox(height: 18),
                      for (final (i, (step, label)) in _steps.indexed)
                        _StepRow(
                          label: label,
                          state: done || (currentIndex > step.index)
                              ? _StepState.done
                              : current == step
                              ? (failed
                                    ? _StepState.failed
                                    : _StepState.running)
                              : _StepState.pending,
                          detail:
                              current == step && s.progress?.received != null
                              ? s.progress!.total != null
                                    ? '${_mb(s.progress!.received!)} of ${_mb(s.progress!.total!)}'
                                    : _mb(s.progress!.received!)
                              : null,
                          last: i == _steps.length - 1,
                        ),
                      const SizedBox(height: 18),
                      if (failed && r.needsPassword)
                        PillButton(
                          label: 'Enter password again',
                          tone: PillTone.accent,
                          onPressed: () async {
                            if (await promptForPassword(
                              context,
                              ref,
                              providerId,
                            )) {
                              await retry();
                            }
                          },
                        )
                      else if (failed)
                        ErrorPanel(
                          error:
                              r.error ??
                              const ConnectionError(
                                ConnectionErrorKind.malformed,
                              ),
                          onRetry: retry,
                          onConnectionCheck: () => context.push(
                            '/connection-check',
                            extra: ConnectionCheckArgs(providerId: providerId),
                          ),
                          extraActions: [
                            PillButton(
                              label: 'Change details',
                              onPressed: changeDetails,
                            ),
                          ],
                        )
                      else
                        PillButton(
                          label: canBrowse ? 'Start browsing' : 'Loading…',
                          tone: PillTone.accent,
                          expand: true,
                          autofocus: true,
                          onPressed: canBrowse
                              ? () => context.go('/home')
                              : null,
                        ),
                      if (!failed && canBrowse && !done)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'Movies, series and the guide keep loading in the background.',
                            style: t.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _StepState { pending, running, done, failed }

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.state,
    this.detail,
    required this.last,
  });

  final String label;
  final _StepState state;
  final String? detail;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    final icon = switch (state) {
      _StepState.done => const Icon(
        Icons.check_circle,
        color: Color(0xFF18A05A),
        size: 22,
      ),
      _StepState.failed => Icon(Icons.error, color: c.accent, size: 22),
      _StepState.running => SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
      ),
      _StepState.pending => Icon(
        Icons.radio_button_unchecked,
        color: c.muted,
        size: 22,
      ),
    };
    return Semantics(
      label: '$label: ${state.name}',
      child: Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 12),
        child: Row(
          children: [
            SizedBox(width: 24, child: Center(child: icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: t.bodyLarge?.copyWith(
                  color: state == _StepState.pending ? c.muted : c.text,
                ),
              ),
            ),
            if (detail != null) Text(detail!, style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}
