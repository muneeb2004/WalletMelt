import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/utils/number_parser.dart';

void main() {
  group('parseTolerantNumber Tests', () {
    test('parses simple integers and decimals', () {
      expect(parseTolerantNumber('100'), 100.0);
      expect(parseTolerantNumber('100.50'), 100.50);
      expect(parseTolerantNumber('0.99'), 0.99);
      expect(parseTolerantNumber('0'), 0.0);
    });

    test('parses thousand separators with commas', () {
      expect(parseTolerantNumber('1,000'), 1000.0);
      expect(parseTolerantNumber('1,250.50'), 1250.50);
      expect(parseTolerantNumber('1,000,000'), 1000000.0);
      expect(parseTolerantNumber('1,000,000.75'), 1000000.75);
    });

    test('parses European comma decimals', () {
      expect(parseTolerantNumber('1250,50'), 1250.50);
      expect(parseTolerantNumber('25,5'), 25.5);
      expect(parseTolerantNumber('1.250,50'), 1250.50);
      expect(parseTolerantNumber('1.000.000,50'), 1000000.50);
    });

    test('parses space-separated numbers', () {
      expect(parseTolerantNumber('1 250.50'), 1250.50);
      expect(parseTolerantNumber('1 000 000'), 1000000.0);
      expect(parseTolerantNumber(' 500.25 '), 500.25);
    });

    test('strips currency prefixes, suffixes, and extraneous characters', () {
      expect(parseTolerantNumber(r'$1,250.50'), 1250.50);
      expect(parseTolerantNumber('Rs 5,000'), 5000.0);
      expect(parseTolerantNumber('€45,99'), 45.99);
      expect(parseTolerantNumber('150 USD'), 150.0);
      expect(parseTolerantNumber('approx. 250.00'), 250.0);
    });

    test('handles accidental duplicate punctuation typos', () {
      expect(parseTolerantNumber('1..50'), 1.50);
      expect(parseTolerantNumber('12,,50'), 12.50);
    });

    test('handles negative numbers', () {
      expect(parseTolerantNumber('-50.25'), -50.25);
      expect(parseTolerantNumber(r'-$100'), -100.0);
    });

    test('returns null for non-numeric or empty input', () {
      expect(parseTolerantNumber(null), isNull);
      expect(parseTolerantNumber(''), isNull);
      expect(parseTolerantNumber('   '), isNull);
      expect(parseTolerantNumber('abc'), isNull);
      expect(parseTolerantNumber(r'$ --'), isNull);
    });
  });
}
