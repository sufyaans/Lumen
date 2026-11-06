import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/browse_catalog.dart';
import '../../domain/media_summary.dart';
import '../common/catalog_screen.dart';

class SeriesScreen extends ConsumerWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => CategoryBrowser(
    kind: MediaKind.series,
    title: 'TV Shows',
    allRows: ref.watch(browseCatalogProvider).series,
    emptyMessage:
        'No TV shows yet. Add a provider in Account to see them here.',
  );
}
