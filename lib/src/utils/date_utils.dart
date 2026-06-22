import 'package:intl/intl.dart';

final _monthKeyFormat = DateFormat('yyyy-MM');
final _readableMonthFormat = DateFormat('MMMM yyyy');
final Map<String, DateTime> _isoDateCache = {};

String monthKey(DateTime date) => _monthKeyFormat.format(date);

String readableMonth(DateTime date) => _readableMonthFormat.format(date);

DateTime parseIsoDate(String value) {
  return _isoDateCache.putIfAbsent(value, () => DateTime.parse(value).toLocal());
}

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;
