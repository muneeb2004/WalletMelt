import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/data/local/wallet_melt_database.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_store_repository.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/utils/merchant_normalizer.dart';

void main() {
  late WalletMeltDatabase db;
  late DriftStoreRepository repository;
  late DriftExpenseRepository expenseRepository;

  setUp(() {
    db = WalletMeltDatabase(NativeDatabase.memory());
    repository = DriftStoreRepository(db);
    expenseRepository = DriftExpenseRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftStoreRepository & Invariant Tests', () {
    test('normalizeMerchantName collapses whitespace, lowercases, and trims', () {
      expect(normalizeMerchantName('  Subway   Clifton  '), 'subway clifton');
      expect(normalizeMerchantName('SUBWAY'), 'subway');
      expect(normalizeMerchantName('AutoCare\nGarage'), 'autocare garage');
    });

    test('recordMerchantHistory resolves to single canonical record across casings and whitespaces', () async {
      final id1 = await repository.recordMerchantHistory('  Subway  ');
      final id2 = await repository.recordMerchantHistory('subway');
      final id3 = await repository.recordMerchantHistory('SUBWAY');

      expect(id1, isNotNull);
      expect(id2, id1);
      expect(id3, id1);

      final merchant = await repository.getByNormalizedName('subway');
      expect(merchant, isNotNull);
      expect(merchant!.name, 'Subway');
      expect(merchant.normalizedName, 'subway');
      expect(merchant.isSaved, isFalse);
      expect(merchant.isFavorite, isFalse);
      expect(merchant.lastUsedAt, isNotNull);
    });

    test('recordMerchantHistory preserves saved state and defaultCategoryId on existing merchant', () async {
      // User explicitly saves Subway with default category 'grocery'
      final saved = await repository.saveMerchant(
        name: 'Subway',
        defaultCategoryId: 'grocery',
        notes: 'Preferred lunch spot',
        isFavorite: true,
      );
      expect(saved.isSaved, isTrue);
      expect(saved.isFavorite, isTrue);
      expect(saved.defaultCategoryId, 'grocery');

      // Subsequent expense usage via recordMerchantHistory
      final historyId = await repository.recordMerchantHistory('  subway  ');
      expect(historyId, saved.id);

      final reloaded = await repository.getById(saved.id);
      expect(reloaded!.isSaved, isTrue);
      expect(reloaded.isFavorite, isTrue);
      expect(reloaded.defaultCategoryId, 'grocery');
      expect(reloaded.notes, 'Preferred lunch spot');
    });

    test('saveMerchant promotes history entry to isSaved=true', () async {
      // First discovered from expense history
      final historyId = await repository.recordMerchantHistory('Shell Fuel');
      final historyMerchant = await repository.getById(historyId!);
      expect(historyMerchant!.isSaved, isFalse);

      // User later saves it from management screen or inline button
      final promoted = await repository.saveMerchant(
        name: 'Shell Fuel',
        defaultCategoryId: 'fuel',
        isFavorite: true,
      );

      expect(promoted.id, historyId);
      expect(promoted.isSaved, isTrue);
      expect(promoted.isFavorite, isTrue);
      expect(promoted.defaultCategoryId, 'fuel');

      final savedList = await repository.listSavedMerchants();
      expect(savedList.any((m) => m.id == historyId), isTrue);
    });

    test('isFavorite=true invariant strictly enforces isSaved=true', () async {
      final merchant = await repository.saveMerchant(
        name: 'AutoCare',
        isFavorite: true,
      );
      expect(merchant.isSaved, isTrue);
      expect(merchant.isFavorite, isTrue);

      final toggled = await repository.toggleFavorite(merchant.id);
      expect(toggled!.isFavorite, isFalse);
      expect(toggled.isSaved, isTrue);

      // Toggle back to favorite
      final toggledBack = await repository.toggleFavorite(merchant.id);
      expect(toggledBack!.isFavorite, isTrue);
      expect(toggledBack.isSaved, isTrue);
    });

    test('archiveMerchant hides from suggestions and saved list, restoreMerchant restores it', () async {
      final merchant = await repository.saveMerchant(
        name: 'Old Mart',
        defaultCategoryId: 'grocery',
      );

      var suggestions = await repository.getSuggestions(query: 'Old');
      expect(suggestions.any((m) => m.id == merchant.id), isTrue);

      await repository.archiveMerchant(merchant.id);

      var savedList = await repository.listSavedMerchants();
      expect(savedList.any((m) => m.id == merchant.id), isFalse);

      suggestions = await repository.getSuggestions(query: 'Old');
      expect(suggestions.any((m) => m.id == merchant.id), isFalse);

      // Restore
      await repository.restoreMerchant(merchant.id);
      savedList = await repository.listSavedMerchants();
      expect(savedList.any((m) => m.id == merchant.id), isTrue);
    });

    test('renaming a merchant updates normalizedName and merges upon collision', () async {
      await repository.saveMerchant(name: 'Subway');
      final m2 = await repository.saveMerchant(name: 'Subway Clifton', defaultCategoryId: 'grocery');

      // Update m2 to rename to 'Subway'
      final merged = await repository.updateMerchant(
        m2.copyWith(name: 'Subway'),
      );

      expect(merged.name, 'Subway');
      expect(merged.defaultCategoryId, 'grocery');

      // Duplicate record was merged and cleaned up
      final list = await repository.listSavedMerchants();
      expect(list.length, 1);
    });

    test('suggestions prioritize favorites, saved merchants, and 90-day recency', () async {
      final now = DateTime.now();

      // Favorite
      await repository.saveMerchant(name: 'Fav Cafe', isFavorite: true);
      // Saved
      await repository.saveMerchant(name: 'Saved Shop', isFavorite: false);
      // Recent history (<90 days)
      await repository.recordMerchantHistory('Recent Mart');
      // Old history (>90 days)
      final oldId = await repository.recordMerchantHistory('Old Ancient Store');
      final hundredDaysAgo = now.subtract(const Duration(days: 100)).toIso8601String();
      await (db.update(db.stores)..where((s) => s.id.equals(oldId!))).write(
        StoresCompanion(lastUsedAt: Value(hundredDaysAgo)),
      );

      final emptyQuerySuggestions = await repository.getSuggestions();

      // Should include Fav Cafe, Saved Shop, Recent Mart
      final names = emptyQuerySuggestions.map((m) => m.name).toList();
      expect(names, contains('Fav Cafe'));
      expect(names, contains('Saved Shop'));
      expect(names, contains('Recent Mart'));
      // Old history is excluded from empty query suggestions
      expect(names, isNot(contains('Old Ancient Store')));
      // Fav Cafe must rank first
      expect(emptyQuerySuggestions.first.name, 'Fav Cafe');
    });

    test('typeahead query prioritizes prefix matches over substring contains matches', () async {
      await repository.saveMerchant(name: 'All Star Subway'); // contains 'sub'
      await repository.saveMerchant(name: 'Subway Express');   // prefix 'sub'

      final suggestions = await repository.getSuggestions(query: 'sub');
      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.first.name, 'Subway Express');
    });
  });

  group('Expense & Store Referential Integrity Tests', () {
    test('creating expense with vendor records merchant history and populates storeId', () async {
      final expense = await expenseRepository.create(
        ExpenseDraft(
          amount: 500,
          currency: 'PKR',
          categoryId: 'grocery',
          title: 'Lunch',
          vendor: 'Subway Gulberg',
          date: DateTime(2026, 8, 24),
        ),
      );

      expect(expense.vendor, 'Subway Gulberg');
      final store = await repository.getByNormalizedName('subway gulberg');
      expect(store, isNotNull);
      expect(store!.name, 'Subway Gulberg');

      final expenseRow = await (db.select(db.expenses)..where((e) => e.id.equals(expense.id))).getSingle();
      expect(expenseRow.storeId, store.id);
    });

    test('updating expense amount does not re-touch merchant or create duplicate', () async {
      final expense = await expenseRepository.create(
        ExpenseDraft(
          amount: 500,
          currency: 'PKR',
          categoryId: 'grocery',
          title: 'Lunch',
          vendor: 'Subway',
          date: DateTime(2026, 8, 24),
        ),
      );

      final storeBefore = await repository.getByNormalizedName('subway');
      final lastUsedBefore = storeBefore!.lastUsedAt;

      // Update amount only
      await expenseRepository.update(expense.copyWith(amount: 750));

      final storeAfter = await repository.getByNormalizedName('subway');
      expect(storeAfter!.id, storeBefore.id);
      expect(storeAfter.lastUsedAt, lastUsedBefore);
    });

    test('updating expense vendor records history for new vendor and updates storeId', () async {
      final expense = await expenseRepository.create(
        ExpenseDraft(
          amount: 500,
          currency: 'PKR',
          categoryId: 'grocery',
          title: 'Lunch',
          vendor: 'Subway',
          date: DateTime(2026, 8, 24),
        ),
      );

      await expenseRepository.update(expense.copyWith(vendor: 'McDonalds'));

      final mcdStore = await repository.getByNormalizedName('mcdonalds');
      expect(mcdStore, isNotNull);

      final updatedRow = await (db.select(db.expenses)..where((e) => e.id.equals(expense.id))).getSingle();
      expect(updatedRow.vendor, 'McDonalds');
      expect(updatedRow.storeId, mcdStore!.id);
    });
  });
}
