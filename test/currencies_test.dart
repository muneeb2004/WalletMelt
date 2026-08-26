import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/analytics/analytics_constants.dart';
import 'package:wallet_melt/src/constants/currencies.dart';
import 'package:wallet_melt/src/utils/currency_format.dart';

void main() {
  group('Currencies of Countries Recognized by Pakistan', () {
    test('Default currency is PKR (Pakistani Rupee)', () {
      expect(supportedCurrencies.first.code, 'PKR');
      expect(supportedCurrencies.first.name, 'Pakistani Rupee');
      expect(supportedCurrencies.first.symbol, 'Rs ');
      expect(supportedCurrencies.first.country, 'Pakistan');
      expect(findCurrency('PKR')?.code, 'PKR');
      expect(isCurrencySupported('PKR'), isTrue);
    });

    test('Strictly excludes currencies of unrecognized countries (Armenia and Israel)', () {
      // Pakistan does not recognize Armenia (AMD)
      expect(isCurrencySupported('AMD'), isFalse,
          reason: 'Armenia is not recognized by Pakistan; AMD must not be supported');
      expect(findCurrency('AMD'), isNull);
      expect(supportedCurrencyCodes.contains('AMD'), isFalse);
      expect(defaultCurrencyCodes.contains('AMD'), isFalse);

      // Pakistan does not recognize Israel (ILS)
      expect(isCurrencySupported('ILS'), isFalse,
          reason: 'Israel is not recognized by Pakistan; ILS must not be supported');
      expect(findCurrency('ILS'), isNull);
      expect(supportedCurrencyCodes.contains('ILS'), isFalse);
      expect(defaultCurrencyCodes.contains('ILS'), isFalse);
    });

    test('Includes major global and regional partner currencies', () {
      final requiredPartnerCodes = [
        'PKR', // Pakistan
        'USD', // United States / Palestine
        'EUR', // Eurozone / Kosovo
        'GBP', // United Kingdom
        'AED', // UAE
        'SAR', // Saudi Arabia
        'CAD', // Canada
        'AUD', // Australia
        'CNY', // China
        'JPY', // Japan
        'INR', // India
        'BDT', // Bangladesh
        'TRY', // Turkey
        'MYR', // Malaysia
        'SGD', // Singapore
        'QAR', // Qatar
        'KWD', // Kuwait
        'OMR', // Oman
        'BHD', // Bahrain
        'AFN', // Afghanistan
        'AZN', // Azerbaijan
        'IRR', // Iran
        'IQD', // Iraq
        'EGP', // Egypt
        'IDR', // Indonesia
        'JOD', // Jordan
        'LBP', // Lebanon
        'SYP', // Syria
        'RUB', // Russia
        'CHF', // Switzerland
        'ZAR', // South Africa
        'BRL', // Brazil
        'KRW', // South Korea
        'NZD', // New Zealand
        'MXN', // Mexico
      ];

      for (final code in requiredPartnerCodes) {
        expect(isCurrencySupported(code), isTrue,
            reason: '$code should be supported as a currency of a recognized state');
        expect(findCurrency(code), isNotNull);
      }
    });

    test('All supported currencies have valid metadata', () {
      final seenCodes = <String>{};

      for (final currency in supportedCurrencies) {
        // ISO 4217 code validation: 3 uppercase letters
        expect(currency.code.length, 3,
            reason: '${currency.code} must be a 3-letter ISO code');
        expect(currency.code, currency.code.toUpperCase(),
            reason: '${currency.code} must be uppercase');
        expect(RegExp(r'^[A-Z]{3}$').hasMatch(currency.code), isTrue,
            reason: '${currency.code} must consist only of A-Z');

        // No duplicate codes
        expect(seenCodes.contains(currency.code), isFalse,
            reason: 'Duplicate currency code: ${currency.code}');
        seenCodes.add(currency.code);

        // Required non-empty fields
        expect(currency.name.trim().isNotEmpty, isTrue,
            reason: '${currency.code} name must not be empty');
        expect(currency.symbol.trim().isNotEmpty, isTrue,
            reason: '${currency.code} symbol must not be empty');
        expect(currency.country.trim().isNotEmpty, isTrue,
            reason: '${currency.code} country must not be empty');
        expect(currency.displayLabel.trim().isNotEmpty, isTrue);
      }

      expect(supportedCurrencies.length, greaterThanOrEqualTo(140),
          reason: 'Should support at least 140 circulating national currencies');
    });

    test('findCurrency is case-insensitive and handles null/empty safely', () {
      expect(findCurrency('pkr')?.code, 'PKR');
      expect(findCurrency('Usd')?.code, 'USD');
      expect(findCurrency('eur')?.code, 'EUR');
      expect(findCurrency(''), isNull);
      expect(findCurrency(null), isNull);
      expect(findCurrency('XYZ_INVALID'), isNull);
    });

    test('formatMoney formats amounts with accurate symbols without throwing', () {
      expect(formatMoney(1500, 'PKR'), contains('Rs'));
      expect(formatMoney(100, 'USD'), contains(r'$'));
      expect(formatMoney(50, 'EUR'), contains('€'));
      expect(formatMoney(75, 'GBP'), contains('£'));
      expect(formatMoney(200, 'AED'), contains('AED'));
      expect(formatMoney(350, 'SAR'), contains('SAR'));
      expect(formatMoney(1200, 'JPY'), contains('¥'));
      expect(formatMoney(500, 'TRY'), contains('₺'));
      expect(formatMoney(1000, 'BDT'), contains('৳'));
      expect(formatMoney(250, 'CAD'), contains(r'CA$'));
      expect(formatMoney(300, 'AUD'), contains(r'A$'));
      expect(formatMoney(100, 'KWD'), contains('KD'));
      expect(formatMoney(200, 'QAR'), contains('QR'));
      expect(formatMoney(50, 'OMR'), contains('RO'));
      expect(formatMoney(100, 'BHD'), contains('BD'));
      expect(formatMoney(500, 'AFN'), contains('؋'));

      // Check minor units formatting
      expect(formatMoneyMinorUnits(150000, 'PKR'), contains('1,500'));
      expect(formatMoneyMinorUnits(1050, 'USD'), contains('10.5'));
    });

    test('AnalyticsConstants.minimumMeaningfulAmount provides positive thresholds for all currencies', () {
      for (final currency in supportedCurrencies) {
        final minAmount = AnalyticsConstants.minimumMeaningfulAmount(currency.code);
        expect(minAmount, greaterThan(0),
            reason: '${currency.code} threshold must be greater than 0');
      }

      // Check specific high-denomination currency thresholds
      expect(AnalyticsConstants.minimumMeaningfulAmount('VND'), 100000.0);
      expect(AnalyticsConstants.minimumMeaningfulAmount('IDR'), 50000.0);
      expect(AnalyticsConstants.minimumMeaningfulAmount('JPY'), 500.0);
      expect(AnalyticsConstants.minimumMeaningfulAmount('KRW'), 5000.0);
      expect(AnalyticsConstants.minimumMeaningfulAmount('PKR'), 500.0);
      expect(AnalyticsConstants.minimumMeaningfulAmount('USD'), 5.0);
    });
  });
}
