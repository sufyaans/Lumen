import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/platform/form_factor.dart';
import '../../core/widgets/artwork.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/content_row.dart';
import '../../data/db/app_database.dart';
import '../account/account_screen.dart';
import 'app_settings.dart';
import 'parental_pin.dart';

/// Settings (brief section 3).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final n = ref.read(appSettingsProvider.notifier);
    final ff = ref.watch(formFactorProvider);
    final t = Theme.of(context).textTheme;
    final g = pageGutter(context);

    Future<void> clearCache() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Clear cache?'),
          content: const Text(
            'This removes saved artwork, the TV guide and episode lists. Your providers, favourites and progress stay. '
            'Everything reloads the next time it is needed.',
          ),
          actions: [
            PillButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            PillButton(
              label: 'Clear',
              tone: PillTone.danger,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await LumenImageCache.clear();
      final db = ref.read(appDatabaseProvider);
      await db.delete(db.epgPrograms).go();
      await db.delete(db.episodes).go();
      await (db.update(db.providers))
          .write(const ProvidersCompanion(lastSyncAt: Value(null)));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cache cleared')));
      }
    }

    return Scaffold(
      body: SafeArea(
        child: FocusMemory(
          debugLabel: 'settings',
          child: ListView(
            padding: const EdgeInsets.only(bottom: 60),
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(g, 16, g, 0),
                child: Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back,
                      label: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 14),
                    Text('Settings', style: t.headlineMedium),
                  ],
                ),
              ),
              Panel(
                title: 'Display',
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
                      onChanged: n.setThemeMode,
                    ),
                  ),
                  if (ff != FormFactor.phone)
                    SettingRow(
                      title: 'Display size',
                      subtitle: 'Compact fits the most on screen. Large makes everything bigger.',
                      trailing: Segmented<DisplaySize>(
                        options: const [
                          (DisplaySize.compact, 'Compact'),
                          (DisplaySize.standard, 'Standard'),
                          (DisplaySize.large, 'Large'),
                        ],
                        value:
                            s.displaySize ??
                            (ff == FormFactor.tv
                                ? DisplaySize.compact
                                : DisplaySize.standard),
                        onChanged: n.setDisplaySize,
                      ),
                    ),
                  if (ff == FormFactor.phone)
                    SettingRow(
                      title: 'Rotate to landscape for video',
                      subtitle: 'Switches to landscape when playback starts and back when you leave.',
                      trailing: Segmented<bool>(
                        options: const [(true, 'On'), (false, 'Off')],
                        value: s.rotateForVideo,
                        onChanged: n.setRotateForVideo,
                      ),
                    ),
                ],
              ),
              Panel(
                title: 'Playback',
                children: [
                  SettingRow(
                    title: 'Default stream format',
                    subtitle: 'Auto picks what your provider offers and remembers what works.',
                    trailing: Segmented<StreamFormat>(
                      options: const [
                        (StreamFormat.auto, 'Auto'),
                        (StreamFormat.ts, 'TS'),
                        (StreamFormat.hls, 'HLS'),
                      ],
                      value: s.streamFormat,
                      onChanged: n.setStreamFormat,
                    ),
                  ),
                  SettingRow(
                    title: 'Buffering',
                    subtitle: 'Stable waits longer before starting but handles weak connections better.',
                    trailing: Segmented<BufferingProfile>(
                      options: const [
                        (BufferingProfile.lowLatency, 'Low latency'),
                        (BufferingProfile.balanced, 'Balanced'),
                        (BufferingProfile.stable, 'Stable'),
                      ],
                      value: s.buffering,
                      onChanged: n.setBuffering,
                    ),
                  ),
                  SettingRow(
                    title: 'Hardware decoding',
                    subtitle: 'Turn off if video shows green blocks or stutters on this device.',
                    trailing: Segmented<HardwareDecoding>(
                      options: const [
                        (HardwareDecoding.auto, 'Auto'),
                        (HardwareDecoding.on, 'On'),
                        (HardwareDecoding.off, 'Off'),
                      ],
                      value: s.hardwareDecoding,
                      onChanged: n.setHardwareDecoding,
                    ),
                  ),
                  SettingRow(
                    title: 'Play next episode automatically',
                    trailing: Segmented<bool>(
                      options: const [(true, 'On'), (false, 'Off')],
                      value: s.autoplayNextEpisode,
                      onChanged: n.setAutoplayNextEpisode,
                    ),
                  ),
                ],
              ),
              Panel(
                title: 'Content',
                children: [
                  SettingRow(
                    title: 'Hide adult categories',
                    subtitle: 'Changing this needs your PIN. Kids profiles always hide them.',
                    trailing: Segmented<bool>(
                      options: const [(true, 'Hide'), (false, 'Show')],
                      value: s.hideAdult,
                      onChanged: (v) async {
                        if (v == s.hideAdult) return;
                        if (await requireParentalPin(context, ref)) {
                          await n.setHideAdult(v);
                        }
                      },
                    ),
                  ),
                  SettingRow(
                    title: 'Update catalogue',
                    subtitle: 'On launch updates when the saved catalogue is older than 6 hours.',
                    trailing: Segmented<RefreshPolicy>(
                      options: const [
                        (RefreshPolicy.onLaunch, 'On launch'),
                        (RefreshPolicy.daily, 'Daily'),
                        (RefreshPolicy.manual, 'Manual'),
                      ],
                      value: s.refreshPolicy,
                      onChanged: n.setRefreshPolicy,
                    ),
                  ),
                  SettingRow(
                    title: 'Clear cache',
                    subtitle: 'Artwork, TV guide and episode lists.',
                    trailing: PillButton(
                      label: 'Clear cache',
                      tone: PillTone.danger,
                      onPressed: clearCache,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
