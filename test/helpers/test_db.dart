import 'dart:io';

import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:lumen/data/db/app_database.dart';

/// Opens the app database the way production does: a multi-client drift
/// isolate, so sync isolates ([computeWithDatabase]) can connect and
/// disconnect without shutting the server down.
class TestDb {
  TestDb._(this.db, this._isolate);

  final AppDatabase db;
  final DriftIsolate _isolate;

  static Future<TestDb> open(File file) async {
    final path = file.absolute.path;
    final iso = await DriftIsolate.spawn(() => NativeDatabase(File(path)));
    return TestDb._(AppDatabase(await iso.connect()), iso);
  }

  Future<void> close() async {
    await db.close();
    await _isolate.shutdownAll();
  }
}
