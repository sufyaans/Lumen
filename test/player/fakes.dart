import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lumen/core/network/connection_error.dart';
import 'package:lumen/domain/media_summary.dart';
import 'package:lumen/features/player/playback_engine.dart';
import 'package:lumen/features/player/player_data.dart';
import 'package:lumen/features/settings/app_settings.dart';

/// Engine that records calls and lets tests drive its state.
class FakeEngine implements PlaybackEngine {
  final _c = StreamController<EngineState>.broadcast(sync: true);
  EngineState _s = const EngineState();
  final opened = <Uri>[];
  final startedAt = <Duration?>[];
  int stops = 0;
  int openCount = 0;
  final seeks = <Duration>[];
  HardwareDecoding? hw;
  bool canSeek = true;

  void emit(EngineState s) {
    _s = s;
    _c.add(s);
  }

  void playingAt(Duration pos, {Duration duration = Duration.zero}) => emit(
    EngineState(
      playing: true,
      hasVideo: true,
      position: pos,
      duration: duration,
    ),
  );

  void fail([String e = 'Failed to open']) => emit(_s.copyWith(error: e));

  @override
  Stream<EngineState> get states => _c.stream;
  @override
  EngineState get state => _s;
  @override
  Future<void> configure({
    required BufferingProfile buffering,
    required HardwareDecoding hardwareDecoding,
  }) async {
    hw = hardwareDecoding;
  }

  @override
  Future<void> open(PlaybackSource source, {Duration? start}) async {
    opened.add(source.url);
    startedAt.add(start);
    openCount++;
    emit(const EngineState(buffering: true));
  }

  @override
  Future<void> play() async => emit(_s.copyWith(playing: true));
  @override
  Future<void> pause() async => emit(_s.copyWith(playing: false));
  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    emit(_s.copyWith(position: position));
  }

  @override
  Future<void> stop() async {
    stops++;
    openCount = openCount > 0 ? openCount - 1 : 0;
    _s = const EngineState();
  }

  @override
  Future<bool> seekable() async => canSeek;
  @override
  Future<void> setAudioTrack(String id) async =>
      emit(_s.copyWith(audioTrackId: id));
  @override
  Future<void> setSubtitleTrack(String? id) async =>
      emit(_s.copyWith(subtitleTrackId: id ?? 'no'));
  @override
  Future<void> setHardwareDecoding(HardwareDecoding mode) async => hw = mode;
  @override
  Widget view({required AspectMode aspect}) =>
      const ColoredBox(color: Color(0xFF000000));
  @override
  Future<void> dispose() async => _c.close();
}

List<MediaSummary> channelList(int n) => [
  for (var i = 1; i <= n; i++)
    MediaSummary(
      id: 'live:$i',
      kind: MediaKind.channel,
      title: 'Channel $i',
      channelNumber: 100 + i,
      nowTitle: 'Show $i',
    ),
];

PlayableItem liveItem(String id) => PlayableItem(
  kind: MediaKind.channel,
  remoteId: id,
  title: 'Channel $id',
  channelNumber: 100 + (int.tryParse(id) ?? 0),
  sources: [
    PlaybackSource(url: Uri.parse('http://h/live/u/p/$id.m3u8'), isLive: true),
    PlaybackSource(url: Uri.parse('http://h/live/u/p/$id.ts'), isLive: true),
    PlaybackSource(url: Uri.parse('http://h/u/p/$id'), isLive: true),
  ],
);

PlayableItem movieItem(
  String id, {
  PlayRequest? next,
  MediaKind kind = MediaKind.movie,
}) => PlayableItem(
  kind: kind,
  remoteId: id,
  title: 'Film $id',
  episodeId: kind == MediaKind.series ? 'e$id' : null,
  seriesId: kind == MediaKind.series ? 's1' : null,
  sources: [PlaybackSource(url: Uri.parse('http://h/movie/u/p/$id.mp4'))],
  nextEpisode: next,
);

class FakePlayerData implements PlayerData {
  FakePlayerData({this.channels = const [], this.saved});

  List<MediaSummary> channels;
  Duration? saved;
  ConnectionError? classify;
  final remembered = <String>[];
  final progress = <(String, Duration, Duration)>[];
  final favourites = <String>{};
  final resolved = <String>[];
  final extra = <String, PlayableItem>{};

  @override
  int? get maxConnections => 2;

  @override
  Future<PlayableItem?> resolve(PlayRequest r) async {
    resolved.add(r.episodeId ?? r.itemId);
    if (extra.containsKey(r.episodeId ?? r.itemId))
      return extra[r.episodeId ?? r.itemId];
    final id = r.itemId.split(':').last;
    if (r.itemId.startsWith('live:')) return liveItem(id);
    if (r.itemId.startsWith('movie:')) return movieItem(id);
    return null;
  }

  @override
  Future<List<MediaSummary>> zapList(String? categoryId) async => channels;
  @override
  Future<void> rememberLiveFormat(String ext) async => remembered.add(ext);
  @override
  Future<ConnectionError?> classifyFailure(PlaybackSource source) async =>
      classify;
  @override
  Future<Duration?> savedPosition(PlayableItem item) async => saved;
  @override
  Future<void> saveProgress(
    PlayableItem item,
    Duration position,
    Duration duration,
  ) async =>
      progress.add((item.episodeId ?? item.remoteId, position, duration));
  @override
  Future<void> markWatched(PlayableItem item) async {}
  @override
  Future<bool> toggleFavourite(PlayableItem item) async =>
      favourites.remove(item.remoteId) ? false : favourites.add(item.remoteId);
  @override
  Future<bool> isFavourite(PlayableItem item) async =>
      favourites.contains(item.remoteId);
}
