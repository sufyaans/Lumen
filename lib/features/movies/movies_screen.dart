import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/browse_catalog.dart';
import '../../domain/media_summary.dart';
import '../common/catalog_screen.dart';

class MoviesScreen extends ConsumerWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => CategoryBrowser(
    kind: MediaKind.movie,
    title: 'Movies',
    allRows: ref.watch(browseCatalogProvider).movies,
    emptyMessage: 'No movies yet. Add a provider in Account to see them here.',
  );
}
