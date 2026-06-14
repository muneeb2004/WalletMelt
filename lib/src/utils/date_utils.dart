import 'package:intl/intl.dart';

String monthKey(DateTime date) => DateFormat('yyyy-MM').format(date);

String readableMonth(DateTime date) => DateFormat('MMMM yyyy').format(date);

DateTime parseIsoDate(String value) => DateTime.parse(value).toLocal();

bool isSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
