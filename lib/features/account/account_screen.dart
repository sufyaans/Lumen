import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_config.dart';
import '../../app/theme.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/platform/form_factor.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/content_row.dart';
import '../settings/app_settings.dart';

/// Panel (prototype `.pn`): radius 16 surface card.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    final g = pageGutter(context);
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 880),
        margin: EdgeInsets.fromLTRB(g, 14, g, 0),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(LumenRadii.panel),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: t.titleSmall),
                if (subtitle != null) Text(subtitle!, style: t.bodySmall),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// Account. Phase 0 has appearance and the entry points; the provider card,
/// saved providers, profiles, Connection check and full settings land in
/// Phase 3.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final device = ref.watch(deviceProfileProvider);

    return FocusMemory(
      debugLabel: 'account',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 60),
        children: [
          const _ProfileHeader(name: 'Me'),
          Panel(
            title: 'Providers',
            children: [
              Text(
                'No provider added yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: PillButton(
                  label: 'Add provider',
                  tone: PillTone.primary,
                  icon: Icons.add,
                  onPressed: () => context.push('/add-provider'),
                ),
              ),
            ],
          ),
          Panel(
            title: 'Settings',
            children: [
              SettingRow(
                title: 'Appearance',
                trailing: Segmented<ThemeMode>(
                  options: const [
                    (ThemeMode.system, 'Auto'),
                    (ThemeMode.dark, 'Dark'),
                    (ThemeMode.light, 'Light'),
                  ],
                  value: s.themeMode,
                  onChanged: notifier.setThemeMode,
                ),
              ),
              if (device.formFactor == FormFactor.phone)
                SettingRow(
                  title: 'Rotate to landscape for video',
                  subtitle:
                      'Switches to landscape when playback starts and back '
                      'when you leave.',
                  trailing: Segmented<bool>(
                    options: const [(true, 'On'), (false, 'Off')],
                    value: s.rotateForVideo,
                    onChanged: notifier.setRotateForVideo,
                  ),
                ),
            ],
          ),
          Panel(
            title: 'About',
            children: [
              Text(
                '${AppConfig.appName} ${AppConfig.version} · '
                '${device.formFactor.name}'
                '${device.liteMode ? ' · Lite mode' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: PillButton(
                  label: 'Terms of use',
                  onPressed: () => context.push('/terms?review=1'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final g = pageGutter(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(g, 16, g, 0),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFF7A45), Color(0xFFC2185B)],
              ),
            ),
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: t.headlineMedium?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: t.headlineMedium),
              Text('Profile', style: t.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
