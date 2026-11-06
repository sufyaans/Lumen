import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/browse_catalog.dart';
import '../common/catalog_screen.dart';

class MoviesScreen extends ConsumerWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(browseCatalogProvider);
    return CatalogScreen(
      title: 'Movies',
      rows: c.movies,
      genres: c.movieGenres,
      emptyMessage:
          'No movies yet. Add a provider in Account to see them here.',
    );
  }
}
