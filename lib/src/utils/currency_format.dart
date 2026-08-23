import 'dart:ui';
import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';

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

String formatMoney(num value, String currency) {
  final decimals = value % 1 == 0 ? 0 : 2;
  final key = '${currency}_$decimals';
  final formatter = _formatCache.putIfAbsent(
    key,
    () => NumberFormat.currency(
      name: currency,
      symbol: _symbolFor(currency),
      decimalDigits: decimals,
    ),
  );
  return formatter.format(value);
}

String _symbolFor(String currency) {
  switch (currency) {
    case 'PKR':
      return 'Rs ';
    case 'USD':
      return r'$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'AED':
      return 'AED ';
    case 'SAR':
      return 'SAR ';
    case 'INR':
      return '₹';
    default:
      return '$currency ';
  }
}
