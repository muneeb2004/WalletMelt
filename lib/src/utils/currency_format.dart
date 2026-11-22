import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';

import '../constants/currencies.dart';

const List<FontFeature> kTabularFigures = [FontFeature.tabularFigures()];

TextStyle withTabularFigures(TextStyle? base) {
  return (base ?? const TextStyle()).copyWith(
    fontFeatures: [
      ...?base?.fontFeatures,
      const FontFeature.tabularFigures(),
    ],
  );
}

final Map<String, NumberFormat> _formatCache = {};

/// Converts a floating-point currency amount (e.g. 10.50) to exact integer minor units (e.g. 1050 cents/paisa).
int toMinorUnits(num amount) => (amount * 100).round();

/// Converts integer minor units to a floating-point value strictly for display/formatting.
double fromMinorUnits(int minorUnits) => minorUnits / 100.0;

/// Formats integer minor units directly into a currency string without floating-point arithmetic errors.
String formatMoneyMinorUnits(int minorUnits, String currency) {
  final decimalValue = minorUnits / 100.0;
  return formatMoney(decimalValue, currency);
}

String formatMoney(num value, String currency) {
  // Whole amounts stay compact ("Rs 500"); fractional amounts use the
  // currency's ISO decimal places, and zero-decimal currencies never show any.
  final isoDigits = currencyDecimalDigits(currency);
  final decimals = (isoDigits == 0 || value % 1 == 0) ? 0 : isoDigits;
  final key = '${currency}_$decimals';
  final formatter = _formatCache.putIfAbsent(
    key,
    () => NumberFormat.currency(
      name: currency,
      symbol: currencySymbolFor(currency),
      decimalDigits: decimals,
    ),
  );
  return formatter.format(value);
}

