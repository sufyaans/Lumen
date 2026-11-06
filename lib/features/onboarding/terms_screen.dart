import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_config.dart';
import '../../app/theme.dart';
import '../../core/widgets/buttons.dart';
import '../settings/app_settings.dart';

const termsText =
    '${AppConfig.appName} is a media player. It does not include, sell or '
    'provide any channels, films, series or playlists.\n\n'
    'To watch anything you need a subscription or playlist from your own '
    'provider. Only use ${AppConfig.appName} with content you are entitled '
    'to access, and with login details your provider gave you.\n\n'
    'Your login details and playlists stay on this device. '
    '${AppConfig.appName} has no accounts, no analytics and no ads.';

/// First-run terms (brief section 1). Shown again when [AppConfig.termsVersion]
/// changes. With `review: true` it is a read-only view from Account.
class TermsScreen extends ConsumerWidget {
  const TermsScreen({super.key, this.review = false});

  final bool review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.7, -0.8),
            radius: 1.2,
            colors: [Color.lerp(c.background, c.accent, 0.24)!, c.background],
            stops: const [0, 0.55],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: c.shadow, blurRadius: 80)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppConfig.appName,
                      style: t.headlineSmall?.copyWith(
                        color: c.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Before you start', style: t.headlineMedium),
                    const SizedBox(height: 12),
                    Text(
                      termsText,
                      style: t.bodyLarge?.copyWith(color: c.muted, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    if (review)
                      PillButton(
                        label: 'Close',
                        expand: true,
                        autofocus: true,
                        onPressed: () => context.pop(),
                      )
                    else
                      PillButton(
                        label: 'I understand, continue',
                        tone: PillTone.accent,
                        expand: true,
                        autofocus: true,
                        onPressed: () async {
                          await ref
                              .read(appSettingsProvider.notifier)
                              .acceptTerms();
                          if (context.mounted) context.go('/add-provider');
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
