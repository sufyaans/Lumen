import 'package:flutter/widgets.dart';

/// Lays the app out on a larger virtual canvas and scales it down to the
/// screen, so TVs and tablets show more content per screen ("10-foot UI"
/// density) without every widget needing its own TV sizes.
///
/// A 1080p Android TV reports 960×540 logical pixels, which makes
/// phone-sized layouts look huge. With [scale] 0.75 the app is laid out at
/// 1280×720 and drawn at 75 % size. Hit testing, focus and scrolling work
/// unchanged because [FittedBox] transforms them too.
class DisplayCanvas extends StatelessWidget {
  const DisplayCanvas({super.key, required this.scale, required this.child});

  /// 1.0 = no change; smaller values fit more on screen.
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (scale >= 0.999 || scale <= 0) return child;
    final mq = MediaQuery.of(context);
    final virtual = mq.size / scale;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(
          size: virtual,
          child: MediaQuery(
            data: mq.copyWith(
              size: virtual,
              devicePixelRatio: mq.devicePixelRatio * scale,
              padding: mq.padding / scale,
              viewPadding: mq.viewPadding / scale,
              viewInsets: mq.viewInsets / scale,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
