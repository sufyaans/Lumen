import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/core/platform/form_factor.dart';
import 'package:lumen/core/platform/orientation.dart';

void main() {
  group('resolveFormFactor', () {
    test('TV wins regardless of size', () {
      expect(resolveFormFactor(isTv: true, shortestSideDp: 300), FormFactor.tv);
      expect(
        resolveFormFactor(isTv: true, shortestSideDp: 1080),
        FormFactor.tv,
      );
    });
    test('600 dp shortest side is a tablet (iPad included)', () {
      expect(
        resolveFormFactor(isTv: false, shortestSideDp: 600),
        FormFactor.tablet,
      );
      expect(
        resolveFormFactor(isTv: false, shortestSideDp: 768),
        FormFactor.tablet,
      );
    });
    test('below 600 dp is a phone', () {
      expect(
        resolveFormFactor(isTv: false, shortestSideDp: 599.9),
        FormFactor.phone,
      );
      expect(
        resolveFormFactor(isTv: false, shortestSideDp: 390),
        FormFactor.phone,
      );
    });
  });

  group('isTvFromAndroid', () {
    test('leanback feature', () {
      expect(
        isTvFromAndroid(
          systemFeatures: const ['android.hardware.wifi', leanbackFeature],
          model: 'Chromecast',
        ),
        isTrue,
      );
    });
    test('Fire TV feature or AFT model code', () {
      expect(
        isTvFromAndroid(systemFeatures: const [fireTvFeature], model: 'x'),
        isTrue,
      );
      expect(isTvFromAndroid(systemFeatures: const [], model: 'AFTMM'), isTrue);
      expect(isTvFromAndroid(systemFeatures: const [], model: 'aftka'), isTrue);
    });
    test('phone', () {
      expect(
        isTvFromAndroid(
          systemFeatures: const ['android.hardware.touchscreen'],
          model: 'Pixel 9',
        ),
        isFalse,
      );
    });
  });

  group('shouldUseLiteMode', () {
    test('OS low-RAM flag', () {
      expect(shouldUseLiteMode(isLowRamDevice: true, ramMb: 4096), isTrue);
    });
    test('1 GB stick', () {
      expect(shouldUseLiteMode(isLowRamDevice: false, ramMb: 980), isTrue);
    });
    test('2 GB device and unknown RAM', () {
      expect(shouldUseLiteMode(isLowRamDevice: false, ramMb: 2048), isFalse);
      expect(shouldUseLiteMode(isLowRamDevice: false, ramMb: 0), isFalse);
    });
  });

  group('OrientationPolicy', () {
    test('phone browses in portrait and plays in landscape', () {
      expect(OrientationPolicy.browsing(FormFactor.phone), [
        DeviceOrientation.portraitUp,
      ]);
      expect(
        OrientationPolicy.playback(FormFactor.phone, rotateForVideo: true),
        OrientationPolicy.landscape,
      );
    });
    test('phone with rotation turned off stays portrait', () {
      expect(
        OrientationPolicy.playback(FormFactor.phone, rotateForVideo: false),
        [DeviceOrientation.portraitUp],
      );
    });
    test('tablet allows everything', () {
      expect(OrientationPolicy.browsing(FormFactor.tablet), isEmpty);
      expect(
        OrientationPolicy.playback(FormFactor.tablet, rotateForVideo: true),
        isEmpty,
      );
    });
    test('TV is landscape only', () {
      expect(
        OrientationPolicy.browsing(FormFactor.tv),
        OrientationPolicy.landscape,
      );
      expect(
        OrientationPolicy.playback(FormFactor.tv, rotateForVideo: false),
        OrientationPolicy.landscape,
      );
    });
  });
}
