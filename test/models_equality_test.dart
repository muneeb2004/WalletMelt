import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/types/category.dart';
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/grocery_item.dart';

void main() {
  group('Domain Model Value Equality Tests', () {
    test('Category value equality and hashCode', () {
      const cat1 = Category(
        id: 'cat_1',
        name: 'Groceries',
        icon: 'shopping_cart',
        color: '#FF0000',
        isDefault: true,
        createdAt: '2026-09-01T00:00:00Z',
        updatedAt: '2026-09-01T00:00:00Z',
      );
      const cat2 = Category(
        id: 'cat_1',
        name: 'Groceries',
        icon: 'shopping_cart',
        color: '#FF0000',
        isDefault: true,
        createdAt: '2026-09-01T00:00:00Z',
        updatedAt: '2026-09-01T00:00:00Z',
      );
      const cat3 = Category(
        id: 'cat_2',
        name: 'Fuel',
        icon: 'local_gas_station',
        color: '#00FF00',
        isDefault: false,
        createdAt: '2026-09-01T00:00:00Z',
        updatedAt: '2026-09-01T00:00:00Z',
      );

      expect(cat1, equals(cat2));
      expect(cat1.hashCode, equals(cat2.hashCode));
      expect(cat1, isNot(equals(cat3)));
    });

    test('Expense value equality and hashCode', () {
      final exp1 = Expense(
        id: 'exp_1',
        amount: 25.50,
        currency: 'USD',
        categoryId: 'cat_1',
        title: 'Lunch',
        date: '2026-09-01',
        isRecurring: false,
        createdAt: '2026-09-01T12:00:00Z',
        updatedAt: '2026-09-01T12:00:00Z',
      );
      final exp2 = Expense(
        id: 'exp_1',
        amount: 25.50,
        currency: 'USD',
        categoryId: 'cat_1',
        title: 'Lunch',
        date: '2026-09-01',
        isRecurring: false,
        createdAt: '2026-09-01T12:00:00Z',
        updatedAt: '2026-09-01T12:00:00Z',
      );
      final exp3 = exp1.copyWith(amount: 30.00);

      expect(exp1, equals(exp2));
      expect(exp1.hashCode, equals(exp2.hashCode));
      expect(exp1, isNot(equals(exp3)));
    });

    test('CategoryBudget value equality and hashCode', () {
      const b1 = CategoryBudget(
        id: 'b_1',
        categoryId: 'cat_1',
        amount: 500.0,
        currency: 'USD',
        month: '2026-09',
        createdAt: '2026-09-01T00:00:00Z',
        updatedAt: '2026-09-01T00:00:00Z',
      );
      const b2 = CategoryBudget(
        id: 'b_1',
        categoryId: 'cat_1',
        amount: 500.0,
        currency: 'USD',
        month: '2026-09',
        createdAt: '2026-09-01T00:00:00Z',
        updatedAt: '2026-09-01T00:00:00Z',
      );
      const b3 = CategoryBudget(
        id: 'b_2',
        categoryId: 'cat_1',
        amount: 600.0,
        currency: 'USD',
        month: '2026-09',
        createdAt: '2026-09-01T00:00:00Z',
        updatedAt: '2026-09-01T00:00:00Z',
      );

      expect(b1, equals(b2));
      expect(b1.hashCode, equals(b2.hashCode));
      expect(b1, isNot(equals(b3)));
    });

    test('GroceryItem value equality and hashCode', () {
      const g1 = GroceryItem(
        id: 'g_1',
        expenseId: 'exp_1',
        name: 'Milk',
        amount: 4.50,
        createdAt: '2026-09-01T00:00:00Z',
      );
      const g2 = GroceryItem(
        id: 'g_1',
        expenseId: 'exp_1',
        name: 'Milk',
        amount: 4.50,
        createdAt: '2026-09-01T00:00:00Z',
      );
      const g3 = GroceryItem(
        id: 'g_2',
        expenseId: 'exp_1',
        name: 'Eggs',
        amount: 3.50,
        createdAt: '2026-09-01T00:00:00Z',
      );

      expect(g1, equals(g2));
      expect(g1.hashCode, equals(g2.hashCode));
      expect(g1, isNot(equals(g3)));
    });
  });
}
