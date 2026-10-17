import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart'
    show WalletMeltDatabase;
import 'package:wallet_melt/src/state/app_state.dart';

void main() {
  test('production constructor with a database enables accounts', () async {
    final db = WalletMeltDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(driftDatabase: db);
    expect(state.accountsAvailable, isTrue);
    expect(AppState.test().accountsAvailable, isFalse);
  });
}
