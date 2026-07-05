import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/wallet_melt_database.dart';

final walletMeltDatabaseProvider =
    FutureProvider<WalletMeltDatabase>((ref) async {
  final database = await WalletMeltDatabase.open();
  ref.onDispose(database.close);
  return database;
});
