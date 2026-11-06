import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_config.dart';
import '../../app/theme.dart';
import '../../core/widgets/buttons.dart';

enum ProviderMethod { xtream, m3uLink, m3uFile }

/// Add provider shell. The method tabs are real; the forms and the
/// connection layer behind them are Phase 1 and Phase 3.
class AddProviderScreen extends StatefulWidget {
  const AddProviderScreen({super.key});

  @override
  State<AddProviderScreen> createState() => _AddProviderScreenState();
}

class _AddProviderScreenState extends State<AddProviderScreen> {
  ProviderMethod _method = ProviderMethod.xtream;

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    final canClose = context.canPop();
    return Scaffold(
      body: SafeArea(
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppConfig.appName,
                          style: t.headlineSmall?.copyWith(
                            color: c.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (canClose)
                        RoundIconButton(
                          icon: Icons.close,
                          label: 'Close',
                          onPressed: () => context.pop(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    canClose ? 'Add a provider' : 'Connect your IPTV provider',
                    style: t.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${AppConfig.appName} only plays what your provider '
                    'supplies. Sign in with the details they gave you.',
                    style: t.bodyMedium?.copyWith(color: c.muted),
                  ),
                  const SizedBox(height: 18),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Segmented<ProviderMethod>(
                      options: const [
                        (ProviderMethod.xtream, 'Xtream Codes'),
                        (ProviderMethod.m3uLink, 'M3U link'),
                        (ProviderMethod.m3uFile, 'M3U file'),
                      ],
                      value: _method,
                      onChanged: (m) => setState(() => _method = m),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Sign-in is being built. This screen will take your '
                    'provider details in the next update.',
                    style: t.bodyMedium?.copyWith(color: c.muted),
                  ),
                  const SizedBox(height: 18),
                  PillButton(
                    label: canClose ? 'Back' : 'Browse for now',
                    expand: true,
                    tone: PillTone.accent,
                    autofocus: true,
                    onPressed: () =>
                        canClose ? context.pop() : context.go('/home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
