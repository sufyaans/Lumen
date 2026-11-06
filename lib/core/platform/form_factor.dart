import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FormFactor { phone, tablet, tv }

/// Facts about the device, resolved once at startup.
@immutable
class DeviceProfile {
  const DeviceProfile({
    required this.formFactor,
    required this.liteMode,
    this.isFireTv = false,
  });

  final FormFactor formFactor;

  /// Low-RAM devices (brief section 8): no blur, no heavy animation,
  /// smaller image caches.
  final bool liteMode;
  final bool isFireTv;

  bool get isTv => formFactor == FormFactor.tv;

  @override
  String toString() =>
      'DeviceProfile($formFactor, lite: $liteMode, fireTv: $isFireTv)';
}

/// Android system features that mean "this is a TV".
const leanbackFeature = 'android.software.leanback';
const fireTvFeature = 'amazon.hardware.fire_tv';

/// RAM below this (MB) turns on Lite mode even if the OS doesn't flag the
/// device as low-RAM. 1 GB sticks typically report 900-1000 MB.
const liteModeRamThresholdMb = 1536;

/// Pure resolution logic, kept separate so it can be unit tested.
FormFactor resolveFormFactor({
  required bool isTv,
  required double shortestSideDp,
}) {
  if (isTv) return FormFactor.tv;
  if (shortestSideDp >= 600) return FormFactor.tablet;
  return FormFactor.phone;
}

bool isTvFromAndroid({
  required List<String> systemFeatures,
  required String model,
}) {
  if (systemFeatures.contains(leanbackFeature)) return true;
  if (systemFeatures.contains(fireTvFeature)) return true;
  // Fire TV model codes start with "AFT" (e.g. AFTMM, AFTKA).
  return model.toUpperCase().startsWith('AFT');
}

bool shouldUseLiteMode({required bool isLowRamDevice, required int ramMb}) =>
    isLowRamDevice || (ramMb > 0 && ramMb < liteModeRamThresholdMb);

double _currentShortestSideDp() {
  final views = PlatformDispatcher.instance.views;
  if (views.isEmpty) return 0;
  final v = views.first;
  final size = v.physicalSize / v.devicePixelRatio;
  return size.shortestSide;
}

/// Resolves the device profile. Never throws: any failure falls back to the
/// screen-size heuristic.
Future<DeviceProfile> detectDeviceProfile({DeviceInfoPlugin? plugin}) async {
  final shortest = _currentShortestSideDp();
  if (kIsWeb) {
    return DeviceProfile(
      formFactor: resolveFormFactor(isTv: false, shortestSideDp: shortest),
      liteMode: false,
    );
  }
  try {
    if (Platform.isAndroid) {
      final info = await (plugin ?? DeviceInfoPlugin()).androidInfo;
      final fire =
          info.systemFeatures.contains(fireTvFeature) ||
          info.model.toUpperCase().startsWith('AFT');
      final tv = isTvFromAndroid(
        systemFeatures: info.systemFeatures,
        model: info.model,
      );
      return DeviceProfile(
        formFactor: resolveFormFactor(isTv: tv, shortestSideDp: shortest),
        liteMode: shouldUseLiteMode(
          isLowRamDevice: info.isLowRamDevice,
          ramMb: info.physicalRamSize,
        ),
        isFireTv: fire,
      );
    }
  } catch (e) {
    debugPrint('Device detection failed, using screen size: $e');
  }
  return DeviceProfile(
    formFactor: resolveFormFactor(isTv: false, shortestSideDp: shortest),
    liteMode: false,
  );
}

/// Overridden in main() with the value resolved at startup.
final deviceProfileProvider = Provider<DeviceProfile>(
  (ref) => throw UnimplementedError('deviceProfileProvider not overridden'),
);

final formFactorProvider = Provider<FormFactor>(
  (ref) => ref.watch(deviceProfileProvider).formFactor,
);
