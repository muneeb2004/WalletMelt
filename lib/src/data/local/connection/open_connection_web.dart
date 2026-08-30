import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

QueryExecutor openConnectionImpl({required String name, String? path}) {
  return driftDatabase(
    name: name,
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}

QueryExecutor openInMemoryConnectionImpl() {
  return driftDatabase(
    name: ':memory:',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}

Future<String?> createPreV2BackupImpl(String path) async => null;
