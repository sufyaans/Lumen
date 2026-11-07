import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'test_clip_frames.dart';

/// Builds a real, playable Motion-JPEG AVI from the embedded frames, so the
/// mock server can serve video without FFmpeg or binary files in the repo.
/// libmpv decodes it in software, so it also plays on emulators.
///
/// It also carries a quiet 8 kHz PCM audio track (a short beep every five
/// seconds). Besides checking sound on real devices, audio keeps mpv's
/// clock running where there is no video output at all (emulators without
/// a GLES context): a video-only file would just end at once there.
Uint8List buildTestClip({int seconds = 120, int fps = 5}) {
  final jpegs = [for (final f in testClipFrames) base64Decode(f)];
  final total = seconds * fps;
  final b = BytesBuilder(copy: false);

  void u32(int v, [BytesBuilder? to]) => (to ?? b).add(
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List(),
  );
  void u16(int v, [BytesBuilder? to]) => (to ?? b).add(
    (ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List(),
  );
  void cc(String s, [BytesBuilder? to]) => (to ?? b).add(ascii.encode(s));

  final maxFrame = jpegs.map((j) => j.length).reduce((a, c) => a > c ? a : c);
  final usPerFrame = 1000000 ~/ fps;
  const sampleRate = 8000;
  final samplesPerFrame = sampleRate ~/ fps;
  final audioPerFrame = samplesPerFrame * 2; // 16-bit mono

  // ---- movi: one '00dc' chunk per frame, padded to even length ----
  final movi = BytesBuilder(copy: false);
  final index = BytesBuilder(copy: false);
  var offset = 4; // relative to the 'movi' fourcc
  for (var i = 0; i < total; i++) {
    final j = jpegs[(i ~/ fps) % jpegs.length]; // a new picture every second
    cc('00dc', movi);
    u32(j.length, movi);
    movi.add(j);
    if (j.length.isOdd) movi.addByte(0);
    cc('00dc', index);
    u32(0x10, index); // AVIIF_KEYFRAME
    u32(offset, index);
    u32(j.length, index);
    offset += 8 + j.length + (j.length & 1);

    // Audio for the same 1/fps of a second, interleaved after the frame.
    final pcm = ByteData(audioPerFrame);
    for (var k = 0; k < samplesPerFrame; k++) {
      final n = i * samplesPerFrame + k; // sample number
      final t = n / sampleRate;
      final beep = (t % 5) < 0.12; // 120 ms beep every 5 s
      final v = beep ? (math.sin(2 * math.pi * 880 * t) * 2500).round() : 0;
      pcm.setInt16(k * 2, v, Endian.little);
    }
    cc('01wb', movi);
    u32(audioPerFrame, movi);
    movi.add(pcm.buffer.asUint8List());
    cc('01wb', index);
    u32(0x10, index);
    u32(offset, index);
    u32(audioPerFrame, index);
    offset += 8 + audioPerFrame;
  }
  final moviBytes = movi.takeBytes();
  final indexBytes = index.takeBytes();

  // ---- hdrl ----
  final avih = BytesBuilder(copy: false);
  u32(usPerFrame, avih);
  u32(maxFrame * fps, avih);
  u32(0, avih);
  u32(0x10, avih); // AVIF_HASINDEX
  u32(total, avih);
  u32(0, avih);
  u32(2, avih); // streams: video, audio
  u32(maxFrame + 8, avih);
  u32(testClipWidth, avih);
  u32(testClipHeight, avih);
  for (var i = 0; i < 4; i++) {
    u32(0, avih);
  }

  final strh = BytesBuilder(copy: false);
  cc('vids', strh);
  cc('MJPG', strh);
  u32(0, strh);
  u16(0, strh);
  u16(0, strh);
  u32(0, strh);
  u32(1, strh); // scale
  u32(fps, strh); // rate
  u32(0, strh);
  u32(total, strh);
  u32(maxFrame + 8, strh);
  u32(0xFFFFFFFF, strh); // quality: default
  u32(0, strh);
  u16(0, strh);
  u16(0, strh);
  u16(testClipWidth, strh);
  u16(testClipHeight, strh);

  final strf = BytesBuilder(copy: false);
  u32(40, strf);
  u32(testClipWidth, strf);
  u32(testClipHeight, strf);
  u16(1, strf);
  u16(24, strf);
  cc('MJPG', strf);
  u32(testClipWidth * testClipHeight * 3, strf);
  for (var i = 0; i < 4; i++) {
    u32(0, strf);
  }

  // Audio stream header: PCM, rate/scale in bytes per second / block align.
  final ash = BytesBuilder(copy: false);
  cc('auds', ash);
  u32(0, ash);
  u32(0, ash);
  u16(0, ash);
  u16(0, ash);
  u32(0, ash);
  u32(2, ash); // scale = block align
  u32(sampleRate * 2, ash); // rate = bytes per second
  u32(0, ash);
  u32(total * samplesPerFrame, ash); // length in blocks
  u32(audioPerFrame, ash);
  u32(0xFFFFFFFF, ash);
  u32(2, ash); // sample size
  for (var i = 0; i < 4; i++) {
    u16(0, ash);
  }
  final asf = BytesBuilder(copy: false); // WAVEFORMATEX
  u16(1, asf); // PCM
  u16(1, asf); // mono
  u32(sampleRate, asf);
  u32(sampleRate * 2, asf);
  u16(2, asf);
  u16(16, asf);
  u16(0, asf);

  Uint8List chunk(String id, Uint8List data) {
    final c = BytesBuilder(copy: false);
    cc(id, c);
    u32(data.length, c);
    c.add(data);
    if (data.length.isOdd) c.addByte(0);
    return c.takeBytes();
  }

  Uint8List list(String type, List<Uint8List> parts) {
    final body = BytesBuilder(copy: false);
    cc(type, body);
    for (final p in parts) {
      body.add(p);
    }
    return chunk('LIST', body.takeBytes());
  }

  final hdrl = list('hdrl', [
    chunk('avih', avih.takeBytes()),
    list('strl', [
      chunk('strh', strh.takeBytes()),
      chunk('strf', strf.takeBytes()),
    ]),
    list('strl', [
      chunk('strh', ash.takeBytes()),
      chunk('strf', asf.takeBytes()),
    ]),
  ]);
  final moviList = list('movi', [moviBytes]);
  final idx1 = chunk('idx1', indexBytes);

  final riffBody = BytesBuilder(copy: false);
  cc('AVI ', riffBody);
  riffBody
    ..add(hdrl)
    ..add(moviList)
    ..add(idx1);
  final body = riffBody.takeBytes();
  cc('RIFF');
  u32(body.length);
  b.add(body);
  return b.takeBytes();
}
