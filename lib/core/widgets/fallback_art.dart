import 'package:material_ui/material_ui.dart';

/// Hue derived from a title, same algorithm as the prototype:
/// `h = (h * 31 + charCode) % 360`.
int titleHue(String title) {
  var h = 0;
  for (final unit in title.codeUnits) {
    h = (h * 31 + unit) % 360;
  }
  return h;
}

/// The 145° two-stop gradient the prototype uses for missing artwork.
LinearGradient titleGradient(String title) {
  final h = titleHue(title).toDouble();
  return LinearGradient(
    begin: const Alignment(-0.57, -0.82), // ~145deg in CSS terms
    end: const Alignment(0.57, 0.82),
    colors: [
      HSLColor.fromAHSL(1, h, 0.68, 0.44).toColor(),
      HSLColor.fromAHSL(1, (h + 55) % 360, 0.62, 0.22).toColor(),
    ],
  );
}

/// Generated artwork shown whenever an image is missing or fails to load.
/// Never a broken-image icon (brief section 3).
class FallbackArt extends StatelessWidget {
  const FallbackArt({
    super.key,
    required this.title,
    this.showTitle = false,
    this.titleStyle,
    this.child,
  });

  final String title;
  final bool showTitle;
  final TextStyle? titleStyle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: titleGradient(title)),
      child: DecoratedBox(
        // Soft highlight top-right and a darkening scrim bottom, like the
        // prototype's ::before layer. Cheap: no blur, no saveLayer.
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.6, -0.7),
            radius: 0.9,
            colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.center,
              colors: [Color(0xA6000000), Color(0x00000000)],
            ),
          ),
          child: showTitle
              ? Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style:
                          titleStyle ??
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            shadows: [
                              Shadow(blurRadius: 8, color: Color(0x80000000)),
                            ],
                          ),
                    ),
                  ),
                )
              : child,
        ),
      ),
    );
  }
}
