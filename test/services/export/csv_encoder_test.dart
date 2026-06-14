import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/export/csv_encoder.dart';

void main() {
  group('CsvEncoder', () {
    const encoder = CsvEncoder();

    test('emits simple rows correctly', () {
      final csv = encoder.encodeRows([
        ['id', 'title'],
        ['1', 'Rent'],
      ]);

      expect(csv, 'id,title\n1,Rent');
    });

    test('escapes commas', () {
      expect(
          encoder.encodeRow(['1', 'Grocery, weekly']), '1,"Grocery, weekly"');
    });

    test('escapes quotes', () {
      expect(
          encoder.encodeRow(['1', 'He said "paid"']), '1,"He said ""paid"""');
    });

    test('escapes multiline values', () {
      expect(encoder.encodeRow(['1', 'first line\nsecond line']),
          '1,"first line\nsecond line"');
    });

    test('handles null and empty values', () {
      expect(encoder.encodeRow(['a', null, '', 'b']), 'a,,,b');
    });
  });
}
