import 'package:drift/drift.dart';

QueryExecutor openConnectionImpl({required String name, String? path}) {
  throw UnsupportedError('Platform unsupported');
}

QueryExecutor openInMemoryConnectionImpl() {
  throw UnsupportedError('Platform unsupported');
}

Future<String?> createPreV2BackupImpl(String path) async => null;
