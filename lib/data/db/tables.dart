import 'package:drift/drift.dart';

/// Catalogue content kinds used across tables.
abstract final class ContentKind {
  static const live = 'live';
  static const movie = 'movie';
  static const series = 'series';
  static const episode = 'episode';
}

/// Saved providers. Secrets (password, credential-bearing URLs) are NOT
/// here: they live in secure storage keyed by [id] (brief 4, 5.8).
@DataClassName('ProviderRow')
class Providers extends Table {
  TextColumn get id => text()();

  /// `xtream`, `m3u_url` or `m3u_file`.
  TextColumn get kind => text()();
  TextColumn get name => text()();

  /// Host and port only, for display. Never contains credentials.
  TextColumn get displayHost => text().withDefault(const Constant(''))();

  /// Xtream username. Not a secret on its own (shown in Account), but
  /// still never logged.
  TextColumn get username => text().nullable()();

  /// [ServerEndpoint] JSON: scheme, host, port, basePath.
  TextColumn get endpointJson => text().nullable()();
  TextColumn get userAgentId => text().nullable()();

  /// `ts` or `m3u8`, whichever last worked.
  TextColumn get liveExtension => text().nullable()();
  BoolColumn get allowUntrustedCert =>
      boolean().withDefault(const Constant(false))();
  TextColumn get epgUrl => text().nullable()();
  TextColumn get fileName => text().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  TextColumn get lastSyncError => text().nullable()();
  TextColumn get userInfoJson => text().nullable()();
  TextColumn get serverInfoJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get providerId => text()();

  /// [ContentKind.live], [ContentKind.movie] or [ContentKind.series].
  TextColumn get kind => text()();
  TextColumn get remoteId => text()();
  TextColumn get name => text()();
  BoolColumn get isAdult => boolean().withDefault(const Constant(false))();
  BoolColumn get isKids => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get syncToken => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {providerId, kind, remoteId};
}

@DataClassName('ChannelRow')
@TableIndex(name: 'channels_by_category', columns: {#providerId, #categoryId})
@TableIndex(name: 'channels_by_number', columns: {#providerId, #number})
class Channels extends Table {
  TextColumn get providerId => text()();
  TextColumn get remoteId => text()();
  TextColumn get name => text()();
  IntColumn get number => integer().nullable()();
  TextColumn get logo => text().nullable()();
  TextColumn get epgId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  BoolColumn get tvArchive => boolean().withDefault(const Constant(false))();
  IntColumn get archiveDays => integer().withDefault(const Constant(0))();

  /// M3U entries only. Known credentials are replaced with placeholders
  /// (see [SecretTemplate]); Xtream URLs are built at play time.
  TextColumn get url => text().nullable()();

  /// M3U per-entry HTTP headers as JSON.
  TextColumn get headersJson => text().nullable()();
  BoolColumn get isAdult => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get syncToken => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {providerId, remoteId};
}

@DataClassName('MovieRow')
@TableIndex(name: 'movies_by_category', columns: {#providerId, #categoryId})
@TableIndex(name: 'movies_by_added', columns: {#providerId, #added})
class Movies extends Table {
  TextColumn get providerId => text()();
  TextColumn get remoteId => text()();
  TextColumn get name => text()();
  TextColumn get poster => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get containerExtension =>
      text().withDefault(const Constant('mp4'))();
  RealColumn get rating => real().nullable()();
  IntColumn get year => integer().nullable()();
  DateTimeColumn get added => dateTime().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get headersJson => text().nullable()();
  BoolColumn get isAdult => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get syncToken => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {providerId, remoteId};
}

@DataClassName('SeriesRow')
@TableIndex(name: 'series_by_category', columns: {#providerId, #categoryId})
class SeriesTable extends Table {
  @override
  String get tableName => 'series';

  TextColumn get providerId => text()();
  TextColumn get remoteId => text()();
  TextColumn get name => text()();
  TextColumn get poster => text().nullable()();
  TextColumn get backdrop => text().nullable()();
  TextColumn get plot => text().nullable()();
  TextColumn get genre => text().nullable()();
  RealColumn get rating => real().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get categoryId => text().nullable()();
  DateTimeColumn get lastModified => dateTime().nullable()();

  /// M3U `/series/` entries are playable on their own.
  TextColumn get url => text().nullable()();
  TextColumn get headersJson => text().nullable()();
  BoolColumn get isAdult => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get syncToken => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {providerId, remoteId};
}

/// Cached lazily when a series is opened.
@DataClassName('EpisodeRow')
@TableIndex(name: 'episodes_by_series', columns: {#providerId, #seriesId})
class Episodes extends Table {
  TextColumn get providerId => text()();
  TextColumn get seriesId => text()();
  TextColumn get episodeId => text()();
  IntColumn get season => integer()();
  IntColumn get episodeNum => integer()();
  TextColumn get title => text()();
  TextColumn get containerExtension =>
      text().withDefault(const Constant('mp4'))();
  TextColumn get plot => text().nullable()();
  IntColumn get durationSecs => integer().nullable()();
  TextColumn get image => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {providerId, episodeId};
}

@DataClassName('EpgProgramRow')
@TableIndex(
  name: 'epg_by_channel_time',
  columns: {#providerId, #channelEpgId, #start},
)
class EpgPrograms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get providerId => text()();
  TextColumn get channelEpgId => text()();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get stop => dateTime()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
}

@DataClassName('ProfileRow')
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isKids => boolean().withDefault(const Constant(false))();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

// ---- User data. Keyed by provider id + remote id with no foreign keys to
// catalogue rows, so a catalogue refresh never wipes it (brief 4). --------

@DataClassName('FavouriteRow')
class Favourites extends Table {
  IntColumn get profileId => integer()();
  TextColumn get providerId => text()();
  TextColumn get kind => text()();
  TextColumn get remoteId => text()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {profileId, providerId, kind, remoteId};
}

@DataClassName('MyListRow')
class MyList extends Table {
  @override
  String get tableName => 'my_list';

  IntColumn get profileId => integer()();
  TextColumn get providerId => text()();
  TextColumn get kind => text()();
  TextColumn get remoteId => text()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {profileId, providerId, kind, remoteId};
}

@DataClassName('ProgressRow')
class Progress extends Table {
  IntColumn get profileId => integer()();
  TextColumn get providerId => text()();

  /// [ContentKind.movie] or [ContentKind.episode].
  TextColumn get kind => text()();
  TextColumn get remoteId => text()();

  /// For episodes: the series, so "Continue watching" can show it.
  TextColumn get seriesId => text().nullable()();
  IntColumn get positionMs => integer()();
  IntColumn get durationMs => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {profileId, providerId, kind, remoteId};
}

@DataClassName('RecentRow')
class Recents extends Table {
  IntColumn get profileId => integer()();
  TextColumn get providerId => text()();
  TextColumn get kind => text()();
  TextColumn get remoteId => text()();
  DateTimeColumn get at => dateTime()();

  @override
  Set<Column> get primaryKey => {profileId, providerId, kind, remoteId};
}
