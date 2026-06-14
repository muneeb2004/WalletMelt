import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/export/wallet_melt_json_backup_validator.dart';

void main() {
  group('WalletMeltJsonBackupValidator', () {
    const validator = WalletMeltJsonBackupValidator();

    test('accepts valid backup json', () {
      final validJson = jsonEncode({
        'metadata': {
          'format': 'walletmelt.local_json_backup',
          'format_version': 1,
          'app_version': '0.1.1+2',
          'exported_at': '2026-06-14T09:08:07.000',
          'includes': [
            'expenses',
            'grocery_items',
            'categories',
            'budgets',
            'settings'
          ],
        },
        'expenses': [],
        'grocery_items': [],
        'categories': [],
        'budgets': [],
        'settings': {
          'currency': 'PKR',
          'theme_preference': 'system',
          'has_completed_onboarding': true,
          'last_exported_at': '2026-06-14',
        },
      });

      final result = validator.validate(validJson);
      expect(result.isValid, isTrue);
      expect(result.error, isNull);
    });

    test('accepts valid backup json with null settings', () {
      final validJson = jsonEncode({
        'metadata': {
          'format': 'walletmelt.local_json_backup',
          'format_version': 1,
          'app_version': '0.1.1+2',
          'exported_at': '2026-06-14T09:08:07.000',
          'includes': [
            'expenses',
            'grocery_items',
            'categories',
            'budgets',
            'settings'
          ],
        },
        'expenses': [],
        'grocery_items': [],
        'categories': [],
        'budgets': [],
        'settings': null,
      });

      final result = validator.validate(validJson);
      expect(result.isValid, isTrue);
      expect(result.error, isNull);
    });

    test('rejects malformed JSON', () {
      final result = validator.validate('{invalid json');
      expect(result.isValid, isFalse);
      expect(result.error, contains('Malformed JSON'));
    });

    test('rejects non-object root', () {
      final result = validator.validate('[1, 2, 3]');
      expect(result.isValid, isFalse);
      expect(result.error, contains('Backup root is not a JSON object'));
    });

    test('rejects missing top-level keys', () {
      final invalidJson = jsonEncode({
        'metadata': {
          'format': 'walletmelt.local_json_backup',
          'format_version': 1,
        },
        'expenses': [],
        'categories': [],
        // missing grocery_items, budgets, settings
      });

      final result = validator.validate(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.error, contains('Missing required top-level key'));
    });

    test('rejects missing or non-object metadata', () {
      final invalidJson = jsonEncode({
        'metadata': 'not-an-object',
        'expenses': [],
        'grocery_items': [],
        'categories': [],
        'budgets': [],
        'settings': {},
      });

      final result = validator.validate(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.error, contains('Metadata is not a JSON object'));
    });

    test('rejects unsupported format', () {
      final invalidJson = jsonEncode({
        'metadata': {
          'format': 'unknown_format',
          'format_version': 1,
        },
        'expenses': [],
        'grocery_items': [],
        'categories': [],
        'budgets': [],
        'settings': {},
      });

      final result = validator.validate(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.error, contains('Unsupported format: unknown_format'));
    });

    test('rejects non-integer format version', () {
      final invalidJson = jsonEncode({
        'metadata': {
          'format': 'walletmelt.local_json_backup',
          'format_version': '1', // string instead of int
        },
        'expenses': [],
        'grocery_items': [],
        'categories': [],
        'budgets': [],
        'settings': {},
      });

      final result = validator.validate(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.error, contains('Format version is not an integer'));
    });

    test('rejects unsupported format version', () {
      final invalidJson = jsonEncode({
        'metadata': {
          'format': 'walletmelt.local_json_backup',
          'format_version': 2, // unsupported version
        },
        'expenses': [],
        'grocery_items': [],
        'categories': [],
        'budgets': [],
        'settings': {},
      });

      final result = validator.validate(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.error, contains('Unsupported format version: 2'));
    });

    test('rejects non-list entities', () {
      final invalidJson = jsonEncode({
        'metadata': {
          'format': 'walletmelt.local_json_backup',
          'format_version': 1,
        },
        'expenses': 'not-a-list',
        'grocery_items': [],
        'categories': [],
        'budgets': [],
        'settings': {},
      });

      final result = validator.validate(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.error, contains('expenses is not an array'));
    });

    test('rejects non-object settings', () {
      final invalidJson = jsonEncode({
        'metadata': {
          'format': 'walletmelt.local_json_backup',
          'format_version': 1,
        },
        'expenses': [],
        'grocery_items': [],
        'categories': [],
        'budgets': [],
        'settings': 'not-an-object-or-null',
      });

      final result = validator.validate(invalidJson);
      expect(result.isValid, isFalse);
      expect(
          result.error, contains('settings is neither null nor a JSON object'));
    });
  });
}
