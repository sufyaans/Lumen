import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/browse_catalog.dart';
import '../common/catalog_screen.dart';

class SeriesScreen extends ConsumerWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(browseCatalogProvider);
    return CatalogScreen(
      title: 'TV Shows',
      rows: c.series,
      genres: c.seriesGenres,
      emptyMessage:
          'No TV shows yet. Add a provider in Account to see them here.',
    );
  }
}
