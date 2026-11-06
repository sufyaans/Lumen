import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_config.dart';
import '../../app/theme.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/platform/form_factor.dart';
import '../../core/widgets/buttons.dart';

/// Top-level destinations, in branch order.
enum ShellTab {
  home('Home', Icons.home_outlined, Icons.home),
  live('Live TV', Icons.live_tv_outlined, Icons.live_tv),
  movies('Movies', Icons.movie_outlined, Icons.movie),
  shows('TV Shows', Icons.tv_outlined, Icons.tv),
  account('Account', Icons.person_outline, Icons.person);

  const ShellTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Navigation chrome around the tab branches.
///
/// * Phone: app bar with Search, bottom [NavigationBar].
/// * Tablet and TV: top tab bar like the prototype, Search and profile on
///   the right.
///
/// Back on a non-Home tab returns to Home; Back on Home leaves the app.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _select(int index) => navigationShell.goBranch(
    index,
    // Tapping the current tab again returns to its first page.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ff = ref.watch(formFactorProvider);
    final index = navigationShell.currentIndex;

    final body = PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: FocusMemory(debugLabel: 'branch-$index', child: navigationShell),
    );

    if (ff == FormFactor.phone) {
      return Scaffold(
        appBar: AppBar(
          title: const _Logo(),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: RoundIconButton(
                icon: Icons.search,
                label: 'Search',
                onPressed: () => context.push('/search'),
              ),
            ),
          ],
        ),
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: _select,
          destinations: [
            for (final t in ShellTab.values)
              NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.selectedIcon),
                label: t.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              index: index,
              onSelect: _select,
              autofocusSelected: ff == FormFactor.tv,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Text(
    AppConfig.appName,
    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: LumenColors.of(context).accent,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    ),
  );
}

class _TopBar extends StatefulWidget {
  const _TopBar({
    required this.index,
    required this.onSelect,
    required this.autofocusSelected,
  });

  final int index;
  final ValueChanged<int> onSelect;

  /// On TV something must visibly have focus from the first frame.
  final bool autofocusSelected;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  final _tabNodes = [
    for (final t in ShellTab.values) FocusNode(debugLabel: 'tab-${t.name}'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.autofocusSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final p = FocusManager.instance.primaryFocus;
        if (p == null || p is FocusScopeNode) {
          _tabNodes[widget.index.clamp(0, 3)].requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final n in _tabNodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.index;
    final onSelect = widget.onSelect;
    final w = MediaQuery.sizeOf(context).width;
    final tabs = ShellTab.values.where((t) => t != ShellTab.account).toList();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: 12),
      child: FocusMemory(
        debugLabel: 'top-bar',
        child: Row(
          children: [
            const _Logo(),
            SizedBox(width: (w * 0.02).clamp(8, 28)),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    for (final t in tabs)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: TabPill(
                          label: t.label,
                          selected: index == t.index,
                          focusNode: _tabNodes[t.index],
                          onPressed: () => onSelect(t.index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            RoundIconButton(
              icon: Icons.search,
              label: 'Search',
              onPressed: () => context.push('/search'),
            ),
            const SizedBox(width: 8),
            RoundIconButton(
              icon: Icons.person,
              label: 'Account',
              background: const Color(0xFFC2185B),
              foreground: Colors.white,
              onPressed: () => onSelect(ShellTab.account.index),
              child: Text(
                'M',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
