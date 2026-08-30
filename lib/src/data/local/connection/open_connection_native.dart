import 'dart:io' as io;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

QueryExecutor openConnectionImpl({required String name, String? path}) {
  if (path != null) {
    return NativeDatabase.createInBackground(io.File(path));
  }
  return NativeDatabase.memory();
}

QueryExecutor openInMemoryConnectionImpl() {
  return NativeDatabase.memory();
}

Future<String?> createPreV2BackupImpl(String path) async {
  final dbFile = io.File(path);
  if (!await dbFile.exists()) return null;

  final existingVersion = _readUserVersion(path);
  if (existingVersion <= 0 || existingVersion >= 5) {
    return null;
  }

  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final backupPath = p.join(
    dbFile.parent.path,
    'wallet_melt.pre_v2_$timestamp.db',
  );
  await dbFile.copy(backupPath);

  for (final suffix in ['-wal', '-shm']) {
    final sidecar = io.File('$path$suffix');
    if (await sidecar.exists()) {
      await sidecar.copy('$backupPath$suffix');
    }
  }

  return backupPath;
}

int _readUserVersion(String path) {
  final db = sqlite3.sqlite3.open(path);
  try {
    final result = db.select('PRAGMA user_version;');
    return result.first['user_version'] as int;
  } finally {
    db.close();
  }
}
