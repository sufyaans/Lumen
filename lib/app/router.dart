import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/account/account_screen.dart';
import '../features/detail/detail_screen.dart';
import '../features/diagnostics/connection_check_screen.dart';
import '../features/home/home_screen.dart';
import '../features/live/live_screen.dart';
import '../features/movies/movies_screen.dart';
import '../features/onboarding/terms_screen.dart';
import '../features/providers/add_provider_screen.dart';
import '../features/providers/sign_in_service.dart';
import '../features/providers/sync_progress_screen.dart';
import '../features/search/search_screen.dart';
import '../features/series/series_screen.dart';
import '../features/settings/app_settings.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/app_shell.dart';
import 'data_providers.dart';

abstract final class Routes {
  static const terms = '/terms';
  static const addProvider = '/add-provider';
  static const home = '/home';
  static const live = '/live';
  static const movies = '/movies';
  static const shows = '/shows';
  static const account = '/account';
  static const search = '/search';
  static const settings = '/settings';
  static const connectionCheck = '/connection-check';
  static String syncing(String id) => '/syncing/$id';
  static String detail(String id) => '/detail/${Uri.encodeComponent(id)}';
}

GoRouter buildRouter(Ref ref) {
  // Re-run redirects when the saved provider list changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(providersListProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    refreshListenable: refresh,
    navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'root'),
    initialLocation: Routes.home,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final accepted = ref.read(appSettingsProvider).termsAccepted;
      final atTerms = loc == Routes.terms;
      if (!accepted && !atTerms) return Routes.terms;
      // Release builds have nothing to browse without a provider (brief 1),
      // so first run goes terms -> Add provider. Debug builds may browse
      // the generated preview.
      if (!kDebugMode && accepted && !atTerms) {
        final list = ref.read(providersListProvider).value;
        final open = {
          Routes.addProvider,
          Routes.connectionCheck,
          Routes.settings,
        };
        if (list != null &&
            list.isEmpty &&
            !open.contains(loc) &&
            !loc.startsWith('/syncing')) {
          return Routes.addProvider;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.terms,
        builder: (context, state) =>
            TermsScreen(review: state.uri.queryParameters['review'] == '1'),
      ),
      GoRoute(
        path: Routes.addProvider,
        builder: (context, state) => const AddProviderScreen(),
      ),
      GoRoute(
        path: '/syncing/:id',
        builder: (context, state) =>
            SyncProgressScreen(providerId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: Routes.connectionCheck,
        builder: (context, state) => ConnectionCheckScreen(
          args: state.extra is ConnectionCheckArgs
              ? state.extra! as ConnectionCheckArgs
              : const ConnectionCheckArgs(),
        ),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/detail/:id',
        builder: (context, state) =>
            DetailScreen(itemId: state.pathParameters['id'] ?? ''),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          _branch(Routes.home, const HomeScreen()),
          _branch(Routes.live, const LiveScreen()),
          _branch(Routes.movies, const MoviesScreen()),
          _branch(Routes.shows, const SeriesScreen()),
          _branch(Routes.account, const AccountScreen()),
        ],
      ),
    ],
  );
}

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(ref);
  ref.onDispose(router.dispose);
  return router;
});
