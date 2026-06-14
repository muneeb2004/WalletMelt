import 'package:intl/intl.dart';

String formatMoney(num value, String currency) {
  return NumberFormat.currency(
    name: currency,
    symbol: _symbolFor(currency),
    decimalDigits: value % 1 == 0 ? 0 : 2,
  ).format(value);
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
