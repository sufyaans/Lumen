import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/mock_server/mock_xtream_server.dart';
import '../../tool/mock_server/test_clip.dart';

void main() {
  test('test clip is a well-formed MJPEG AVI', () {
    final clip = buildTestClip(seconds: 4, fps: 5);
    final d = ByteData.sublistView(clip);
    String cc(int at) => String.fromCharCodes(clip.sublist(at, at + 4));
    expect(cc(0), 'RIFF');
    expect(d.getUint32(4, Endian.little), clip.length - 8);
    expect(cc(8), 'AVI ');
    expect(cc(12), 'LIST');
    expect(cc(20), 'hdrl');
    // avih: 20 frames, 2 streams.
    expect(cc(24), 'avih');
    expect(d.getUint32(32 + 16, Endian.little), 20);
    expect(d.getUint32(32 + 24, Endian.little), 2);
    // Index at the end has one 16-byte entry per frame.
    final idx = clip.length - (8 + 40 * 16); // video + audio per frame
    expect(cc(idx), 'idx1');
    expect(d.getUint32(idx + 4, Endian.little), 40 * 16);
    expect(String.fromCharCodes(clip.sublist(idx + 24, idx + 28)), '01wb');
    // First index entry points at a JPEG (FF D8) inside 'movi'.
    final moviFourcc = String.fromCharCodes(clip).indexOf('movi');
    final first = moviFourcc + d.getUint32(idx + 16, Endian.little);
    expect(cc(first), '00dc');
    expect(clip[first + 8], 0xFF);
    expect(clip[first + 9], 0xD8);
  });

  test('mock server serves the clip with byte ranges', () async {
    final clip = buildTestClip(seconds: 2);
    final server = await MockXtreamServer.start(
      MockProvider()..videoClip = clip,
    );
    final http = HttpClient();
    try {
      Future<(int, List<int>, String?)> get(String? range) async {
        final req = await http.getUrl(
          Uri.parse('${server.base}/movie/user/pass/1001.mp4'),
        );
        if (range != null) req.headers.set('range', range);
        final res = await req.close();
        final body = await res.fold<List<int>>([], (a, b) => a..addAll(b));
        return (res.statusCode, body, res.headers.value('content-range'));
      }

      final full = await get(null);
      expect(full.$1, 200);
      expect(full.$2.length, clip.length);
      final part = await get('bytes=100-199');
      expect(part.$1, 206);
      expect(part.$2, clip.sublist(100, 200));
      expect(part.$3, 'bytes 100-199/${clip.length}');
      final open = await get('bytes=${clip.length - 10}-');
      expect(open.$2, clip.sublist(clip.length - 10));
      expect((await get('bytes=${clip.length}-')).$1, 416);
    } finally {
      http.close(force: true);
      await server.close();
    }
  });
}
