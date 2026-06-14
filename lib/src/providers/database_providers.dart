import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../data/db/app_database.dart';
import '../data/local/wallet_melt_database.dart';

final walletMeltDatabaseProvider = FutureProvider<WalletMeltDatabase>((ref) async {
  final database = await WalletMeltDatabase.open();
  ref.onDispose(database.close);
  return database;
});

final sqfliteDatabaseProvider = FutureProvider<Database>((ref) {
  return AppDatabase.instance.database;
});
