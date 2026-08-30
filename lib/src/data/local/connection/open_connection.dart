import 'package:drift/drift.dart';

import 'open_connection_stub.dart'
    if (dart.library.io) 'open_connection_native.dart'
    if (dart.library.js_interop) 'open_connection_web.dart';

QueryExecutor openConnection({required String name, String? path}) =>
    openConnectionImpl(name: name, path: path);

QueryExecutor openInMemoryConnection() =>
    openInMemoryConnectionImpl();

Future<String?> createPreV2Backup(String path) =>
    createPreV2BackupImpl(path);
