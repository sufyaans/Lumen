import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'player_data.dart';

/// Opens the full-screen player. The request travels in memory, never in
/// the URL.
Future<void> playItem(BuildContext context, PlayRequest request) =>
    context.push('/play', extra: request);
