import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_config.dart';
import '../../app/data_providers.dart';
import '../../app/theme.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/network/connection_error.dart';
import '../../core/platform/form_factor.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/content_row.dart';
import '../../core/widgets/text_prompt_dialog.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../data/xtream/xtream_models.dart';
import '../common/error_panel.dart';
import '../providers/password_prompt.dart';
import '../providers/sign_in_service.dart';

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
          FittedBox(fit: BoxFit.scaleDown, child: trailing),
        ],
      ),
    );
  }
}

const _avatarGradients = [
  [Color(0xFFFF7A45), Color(0xFFC2185B)],
  [Color(0xFF4FACFE), Color(0xFF4338CA)],
  [Color(0xFF34D399), Color(0xFF0F766E)],
  [Color(0xFFFBBF24), Color(0xFFB45309)],
  [Color(0xFFF472B6), Color(0xFF7E22CE)],
];

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    required this.colorIndex,
    this.size = 72,
  });

  final String name;
  final int colorIndex;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: _avatarGradients[colorIndex % _avatarGradients.length],
      ),
    ),
    child: Text(
      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: size * 0.4,
      ),
    ),
  );
}

/// Details for the active provider card.
class ProviderDetails {
  const ProviderDetails(
    this.row,
    this.user,
    this.channels,
    this.movies,
    this.series,
  );
  final ProviderRow row;
  final UserInfo? user;
  final int channels;
  final int movies;
  final int series;
}

final providerDetailsProvider = FutureProvider.family<ProviderDetails?, String>(
  (ref, id) async {
    ref.watch(catalogVersionProvider);
    ref.watch(providersListProvider);
    final p = await ref.read(providerRegistryProvider).byId(id);
    if (p == null) return null;
    final repo = ref.read(catalogRepositoryProvider);
    UserInfo? user;
    if (p.userInfoJson != null) {
      try {
        final j = jsonDecode(p.userInfoJson!) as Map<String, Object?>;
        user = UserInfo(
          auth: j['auth'] as bool?,
          status: AccountStatus.values.firstWhere(
            (s) => s.name == j['status'],
            orElse: () => AccountStatus.unknown,
          ),
          statusRaw: j['statusRaw'] as String?,
          expiresAt: j['expiresAt'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  j['expiresAt']! as int,
                  isUtc: true,
                ),
          maxConnections: j['maxConnections'] as int?,
          activeConnections: j['activeConnections'] as int?,
          isTrial: j['isTrial'] == true,
        );
      } catch (_) {}
    }
    return ProviderDetails(
      p,
      user,
      await repo.count(id, ContentKind.live),
      await repo.count(id, ContentKind.movie),
      await repo.count(id, ContentKind.series),
    );
  },
);

const _kindNames = {
  'xtream': 'Xtream Codes',
  'm3u_url': 'M3U link',
  'm3u_file': 'M3U file',
};

String _ago(DateTime? d) {
  if (d == null) return 'Not yet';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return '${diff.inHours} h ago';
  return formatDay(d);
}

/// Account (brief section 3): profile, provider card, saved providers,
/// profiles, settings, Connection check, sign out.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final c = LumenColors.of(context);
    final device = ref.watch(deviceProfileProvider);
    final providers =
        ref.watch(providersListProvider).value ?? const <ProviderRow>[];
    final activeId = ref.watch(activeProviderIdProvider);
    final profiles = ref.watch(profilesProvider).value ?? const <ProfileRow>[];
    final profileId = ref.watch(activeProfileIdProvider);
    final profile = profiles.where((p) => p.id == profileId).firstOrNull;
    final sync = ref.watch(syncControllerProvider);
    final details = activeId == null
        ? null
        : ref.watch(providerDetailsProvider(activeId)).value;
    final g = pageGutter(context);

    Future<void> remove(ProviderRow p) async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Remove ${p.name}?'),
          content: const Text(
            'This removes the provider, its saved catalogue, favourites and progress from this device.',
          ),
          actions: [
            PillButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            PillButton(
              label: 'Remove',
              tone: PillTone.danger,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await ref.read(providerRegistryProvider).remove(p.id);
      if (activeId == p.id) {
        await ref.read(activeProviderIdProvider.notifier).select(null);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Provider removed')));
      }
    }

    Future<void> addProfile() async {
      var kids = false;
      final name = await askText(
        context,
        TextPromptDialog(
          title: 'Add profile',
          hint: 'Profile name',
          maxLength: 20,
          confirmLabel: 'Save',
          extra: (set) => Row(
            children: [
              const Expanded(child: Text('Kids profile')),
              Segmented<bool>(
                options: const [(false, 'No'), (true, 'Yes')],
                value: kids,
                onChanged: (v) => set(() => kids = v),
              ),
            ],
          ),
        ),
      );
      final n = name?.trim() ?? '';
      if (n.isEmpty) return;
      final db = ref.read(appDatabaseProvider);
      await db
          .into(db.profiles)
          .insert(
            ProfilesCompanion.insert(
              name: n,
              isKids: Value(kids),
              colorIndex: Value(profiles.length),
              createdAt: DateTime.now(),
            ),
          );
    }

    final needsPassword =
        sync.lastResult?.needsPassword == true ||
        details?.row.lastSyncError == 'needs_password';

    return FocusMemory(
      debugLabel: 'account',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 60),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(g, 16, g, 0),
            child: Row(
              children: [
                ProfileAvatar(
                  name: profile?.name ?? 'Me',
                  colorIndex: profile?.colorIndex ?? 0,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.name ?? 'Me', style: t.headlineMedium),
                      Text(
                        [
                          (profile?.isKids ?? false)
                              ? 'Kids profile'
                              : 'Profile',
                          ?details?.row.name,
                        ].join(' · '),
                        style: t.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (details != null)
            Panel(
              title: 'Provider',
              children: [
                Wrap(
                  spacing: 28,
                  runSpacing: 14,
                  children: [
                    _kv(context, 'Name', details.row.name),
                    _kv(
                      context,
                      'Type',
                      _kindNames[details.row.kind] ?? details.row.kind,
                    ),
                    _kv(
                      context,
                      details.row.kind == 'm3u_file' ? 'File' : 'Server',
                      details.row.kind == 'm3u_file'
                          ? (details.row.fileName ?? '')
                          : details.row.displayHost,
                    ),
                    if (details.row.username != null)
                      _kv(context, 'Username', details.row.username!),
                    if (details.user != null) ...[
                      _kv(
                        context,
                        'Status',
                        details.user!.statusRaw ?? 'Active',
                        good: true,
                      ),
                      _kv(
                        context,
                        'Expires',
                        expiryLabel(details.user!.expiresAt),
                      ),
                      if (details.user!.maxConnections != null)
                        _kv(
                          context,
                          'Connections',
                          '${details.user!.activeConnections ?? 0} of ${details.user!.maxConnections} in use',
                        ),
                    ],
                    _kv(context, 'Live channels', '${details.channels}'),
                    _kv(context, 'Movies', '${details.movies}'),
                    _kv(context, 'Series', '${details.series}'),
                    _kv(context, 'Updated', _ago(details.row.lastSyncAt)),
                  ],
                ),
                const SizedBox(height: 16),
                if (needsPassword)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PillButton(
                      label: 'Enter your password again',
                      tone: PillTone.accent,
                      onPressed: () async {
                        if (await promptForPassword(
                          context,
                          ref,
                          details.row.id,
                        )) {
                          await ref
                              .read(syncControllerProvider.notifier)
                              .refresh(details.row.id);
                        }
                      },
                    ),
                  )
                else if (sync.lastResult?.error != null &&
                    sync.providerId == details.row.id &&
                    !sync.running)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ErrorPanel(
                      error: sync.lastResult!.error!,
                      onRetry: () => ref
                          .read(syncControllerProvider.notifier)
                          .refresh(details.row.id),
                    ),
                  ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (details.row.kind != 'm3u_file')
                      PillButton(
                        label: sync.running ? 'Refreshing…' : 'Refresh',
                        icon: Icons.refresh,
                        tone: PillTone.primary,
                        onPressed: sync.running
                            ? null
                            : () => ref
                                  .read(syncControllerProvider.notifier)
                                  .refresh(details.row.id),
                      ),
                    if (details.row.kind != 'm3u_file')
                      PillButton(
                        label: 'Connection check',
                        icon: Icons.network_check,
                        onPressed: () => context.push(
                          '/connection-check',
                          extra: ConnectionCheckArgs(
                            providerId: details.row.id,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          Panel(
            title: 'Providers',
            children: [
              if (providers.isEmpty)
                Text('No provider added yet.', style: t.bodyMedium),
              for (final p in providers)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: t.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_kindNames[p.kind] ?? p.kind} · ${p.kind == 'm3u_file' ? (p.fileName ?? '') : p.displayHost}',
                              style: t.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (p.id == activeId)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: c.accent.withAlpha(46),
                            borderRadius: BorderRadius.circular(
                              LumenRadii.pill,
                            ),
                          ),
                          child: Text(
                            'In use',
                            style: t.labelMedium?.copyWith(color: c.accent),
                          ),
                        )
                      else
                        PillButton(
                          label: 'Use',
                          onPressed: () => ref
                              .read(activeProviderIdProvider.notifier)
                              .select(p.id),
                        ),
                      const SizedBox(width: 8),
                      PillButton(
                        label: 'Remove',
                        tone: PillTone.danger,
                        onPressed: () => remove(p),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
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
            title: 'Profiles',
            children: [
              for (final p in profiles)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      ProfileAvatar(
                        name: p.name,
                        colorIndex: p.colorIndex,
                        size: 42,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: t.titleSmall),
                            Text(
                              p.isKids
                                  ? 'Kids profile: adult and most channels hidden'
                                  : 'Full library',
                              style: t.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (p.id == profileId)
                        Text(
                          'Watching',
                          style: t.labelMedium?.copyWith(color: c.accent),
                        )
                      else
                        PillButton(
                          label: 'Switch',
                          onPressed: () async {
                            await ref
                                .read(activeProfileIdProvider.notifier)
                                .select(p.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Switched to ${p.name}'),
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
              if (profiles.length < 5)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: PillButton(
                      label: 'Add profile',
                      icon: Icons.person_add_alt,
                      onPressed: addProfile,
                    ),
                  ),
                ),
            ],
          ),
          Panel(
            title: 'Settings',
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  PillButton(
                    label: 'Settings',
                    icon: Icons.settings,
                    onPressed: () => context.push('/settings'),
                  ),
                  PillButton(
                    label: 'Terms of use',
                    onPressed: () => context.push('/terms?review=1'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${AppConfig.appName} ${AppConfig.version} · ${device.formFactor.name}'
                '${device.liteMode ? ' · Lite mode' : ''}'
                '${device.formFactor == FormFactor.tv ? ' · TV' : ''}',
                style: t.bodySmall,
              ),
            ],
          ),
          if (activeId != null)
            Panel(
              title: 'Sign out',
              children: [
                PillButton(
                  label: 'Sign out',
                  tone: PillTone.danger,
                  onPressed: () async {
                    await ref
                        .read(activeProviderIdProvider.notifier)
                        .select(null);
                    if (context.mounted) context.go('/add-provider');
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Signing out keeps your saved providers on this device.',
                  style: t.bodySmall,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v, {bool good = false}) {
    final t = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 260),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: t.labelSmall),
          Text(
            v,
            style: t.titleSmall?.copyWith(
              color: good ? const Color(0xFF18A05A) : null,
            ),
          ),
        ],
      ),
    );
  }
}
