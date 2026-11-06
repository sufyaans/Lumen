import 'package:flutter/widgets.dart';

/// 5 % overscan padding on TV (brief section 8). A no-op elsewhere.
class TvSafeArea extends StatelessWidget {
  const TvSafeArea({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  static const double fraction = 0.05;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final size = MediaQuery.sizeOf(context);
    final h = size.width * fraction;
    final v = size.height * fraction;
    return Padding(
      padding: EdgeInsets.fromLTRB(h, v, h, v),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        removeLeft: true,
        removeRight: true,
        child: child,
      ),
    );
  }
}
