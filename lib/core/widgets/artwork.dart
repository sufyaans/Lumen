import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:material_ui/material_ui.dart';

import 'fallback_art.dart';

/// Bounded on-disk image cache (brief section 10). Smaller on TV / Lite.
abstract final class LumenImageCache {
  static CacheManager? _instance;
  static int _max = 600;

  static void configure({required bool small}) => _max = small ? 250 : 600;

  static CacheManager get instance => _instance ??= CacheManager(
    Config(
      'lumenImages',
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: _max,
    ),
  );

  static Future<void> clear() async {
    await instance.emptyCache();
    PaintingBinding.instance.imageCache.clear();
  }
}

/// Network artwork decoded at display size, falling back to generated
/// gradient art when the URL is empty or the image fails. Never a broken
/// image icon (brief section 3).
class Artwork extends StatelessWidget {
  const Artwork({
    super.key,
    required this.title,
    required this.url,
    required this.width,
    this.child,
    this.fit = BoxFit.cover,
  });

  final String title;
  final String? url;

  /// Logical display width, used to decode at the right size.
  final double width;

  /// Drawn over the image (titles, progress bars).
  final Widget? child;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return FallbackArt(title: title, child: child);
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final fallback = FallbackArt(title: title);
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: u,
          cacheManager: LumenImageCache.instance,
          memCacheWidth: (width * dpr).round(),
          fit: fit,
          fadeInDuration: const Duration(milliseconds: 120),
          placeholder: (_, _) => fallback,
          errorWidget: (_, _, _) => fallback,
        ),
        if (child != null)
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Color(0xA6000000), Color(0x00000000)],
              ),
            ),
            child: child,
          ),
      ],
    );
  }
}
