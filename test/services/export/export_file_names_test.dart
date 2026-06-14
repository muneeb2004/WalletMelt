import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/export/export_file_names.dart';

void main() {
  group('buildWalletMeltExportFileName', () {
    test('is deterministic with injected timestamp', () {
      final fileName = buildWalletMeltExportFileName(
        exportKind: 'expenses',
        createdAt: DateTime(2026, 6, 14, 9, 8, 7),
      );

      expect(fileName, 'walletmelt-expenses-20260614-090807.csv');
    });

    test('uses safe lowercase WalletMelt prefix and kind', () {
      final fileName = buildWalletMeltExportFileName(
        exportKind: 'Expense Report!',
        createdAt: DateTime(2026, 6, 14),
      );

      expect(fileName, startsWith('walletmelt-expense-report-'));
      expect(fileName, isNot(contains(' ')));
      expect(fileName, isNot(contains('!')));
    });

    test('has csv extension by default', () {
      final fileName = buildWalletMeltExportFileName(
        exportKind: 'expenses',
        createdAt: DateTime(2026, 6, 14),
      );

      expect(fileName, endsWith('.csv'));
    });
  });
}
