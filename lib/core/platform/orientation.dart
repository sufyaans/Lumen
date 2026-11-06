import 'package:flutter/services.dart';

import 'form_factor.dart';

/// Orientation rules from the brief (section 3).
abstract final class OrientationPolicy {
  static List<DeviceOrientation> browsing(FormFactor f) => switch (f) {
    FormFactor.phone => const [DeviceOrientation.portraitUp],
    FormFactor.tablet => const [],
    FormFactor.tv => landscape,
  };

  static List<DeviceOrientation> playback(
    FormFactor f, {
    required bool rotateForVideo,
  }) {
    if (f == FormFactor.phone && !rotateForVideo) return browsing(f);
    return switch (f) {
      FormFactor.phone => landscape,
      // iPad: landscape preferred but all orientations stay allowed.
      FormFactor.tablet => const [],
      FormFactor.tv => landscape,
    };
  }

  static const landscape = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  static Future<void> applyBrowsing(FormFactor f) =>
      SystemChrome.setPreferredOrientations(browsing(f));

  static Future<void> applyPlayback(
    FormFactor f, {
    required bool rotateForVideo,
  }) => SystemChrome.setPreferredOrientations(
    playback(f, rotateForVideo: rotateForVideo),
  );
}
