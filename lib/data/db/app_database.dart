import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Providers,
    Categories,
    Channels,
    Movies,
    SeriesTable,
    Episodes,
    EpgPrograms,
    Profiles,
    Favourites,
    MyList,
    Progress,
    Recents,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The on-device database. Queries run on a background isolate so the
  /// UI never waits on SQLite, and [computeWithDatabase] can attach more
  /// isolates for bulk writes.
  factory AppDatabase.open() => AppDatabase(
    driftDatabase(
      name: 'lumen',
      native: const DriftNativeOptions(shareAcrossIsolates: true),
    ),
  );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await createSearchIndex(this);
      // A default profile so user data always has an owner.
      await into(
        profiles,
      ).insert(ProfilesCompanion.insert(name: 'Me', createdAt: DateTime.now()));
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = OFF');
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA synchronous = NORMAL');
    },
  );
}

/// FTS5 index over every searchable name (brief 4). Rebuilt per provider
/// after each sync, inside the sync isolate.
Future<void> createSearchIndex(GeneratedDatabase db) => db.customStatement(
  'CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5('
  'name, kind UNINDEXED, provider_id UNINDEXED, remote_id UNINDEXED, '
  'category_id UNINDEXED, is_adult UNINDEXED, '
  "tokenize = 'unicode61 remove_diacritics 2')",
);
