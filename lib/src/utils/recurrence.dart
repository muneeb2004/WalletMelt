/// Shared recurrence arithmetic for subscriptions and income schedules.
///
/// Month-based cycles keep the [anchorDay] and clamp to the last day of the
/// target month (Jan 31 -> Feb 28/29 -> Mar 31), so dates never drift.
/// Supported cycles: weekly, monthly, quarterly, semi_annual / semi-annual,
/// annual / yearly and `custom_N` (N calendar days; N <= 0 falls back to 30).
/// Unknown cycles advance by one month.
DateTime addMonthsClamped(DateTime from, int months, int anchorDay) {
  final total = from.year * 12 + (from.month - 1) + months;
  final year = total ~/ 12;
  final month = total % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, anchorDay > lastDay ? lastDay : anchorDay);
}

DateTime advanceByCycle(String billingCycle, DateTime current, int anchorDay) {
  final cycle = billingCycle.toLowerCase().trim();
  switch (cycle) {
    case 'weekly':
      return DateTime(current.year, current.month, current.day + 7);
    case 'monthly':
      return addMonthsClamped(current, 1, anchorDay);
    case 'quarterly':
      return addMonthsClamped(current, 3, anchorDay);
    case 'semi-annual':
    case 'semi_annual':
      return addMonthsClamped(current, 6, anchorDay);
    case 'annual':
    case 'yearly':
      return addMonthsClamped(current, 12, anchorDay);
  }
  if (cycle.startsWith('custom_')) {
    final parts = cycle.split('_');
    if (parts.length == 2) {
      final parsedDays = int.tryParse(parts[1]) ?? 30;
      final days = parsedDays > 0 ? parsedDays : 30;
      return DateTime(current.year, current.month, current.day + days);
    }
  }
  return addMonthsClamped(current, 1, anchorDay);
}
