enum SubscriptionStatus { active, paused, cancelled }

class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.amount,
    required this.currency,
    required this.startDate,
    required this.nextOccurrenceDate,
    required this.billingCycle,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.taxAmount,
    this.description,
    this.cancelledAt,
    this.notificationOffset,
    this.deletedAt,
    this.version = 1,
  });

  final String id;
  final String name;
  final String categoryId;
  final double amount;
  final double? taxAmount;
  final String currency;
  final String? description;
  final String startDate;
  final String nextOccurrenceDate;
  final String billingCycle; // "monthly", "quarterly", "semi_annual", "annual", or "custom_X" (days interval)
  final SubscriptionStatus status;
  final String createdAt;
  final String updatedAt;
  final String? cancelledAt;
  final int? notificationOffset;
  final String? deletedAt;
  final int version;

  bool get isActive => status == SubscriptionStatus.active;
  bool get isPaused => status == SubscriptionStatus.paused;
  bool get isCancelled => status == SubscriptionStatus.cancelled;
  bool get isDeleted => deletedAt != null;

  /// Day of month the subscription was anchored to (from [startDate]), so that
  /// month-end renewals do not drift (Jan 31 -> Feb 28 -> Mar 31, not Mar 28).
  int get _anchorDay {
    final parsed = DateTime.tryParse(startDate);
    return parsed?.day ?? 31;
  }

  static DateTime _addMonthsClamped(DateTime from, int months, int anchorDay) {
    final total = from.year * 12 + (from.month - 1) + months;
    final year = total ~/ 12;
    final month = total % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, anchorDay > lastDay ? lastDay : anchorDay);
  }

  DateTime calculateNextRenewalDate(DateTime current) {
    final cycle = billingCycle.toLowerCase().trim();
    final anchor = _anchorDay;
    if (cycle == 'monthly') {
      return _addMonthsClamped(current, 1, anchor);
    } else if (cycle == 'quarterly') {
      return _addMonthsClamped(current, 3, anchor);
    } else if (cycle == 'semi-annual' || cycle == 'semi_annual') {
      return _addMonthsClamped(current, 6, anchor);
    } else if (cycle == 'annual' || cycle == 'yearly') {
      return _addMonthsClamped(current, 12, anchor);
    } else if (cycle.startsWith('custom_')) {
      final parts = cycle.split('_');
      if (parts.length == 2) {
        final parsedDays = int.tryParse(parts[1]) ?? 30;
        // A non-positive interval would never advance the date; fall back to 30.
        final days = parsedDays > 0 ? parsedDays : 30;
        return DateTime(current.year, current.month, current.day + days);
      }
    }
    return _addMonthsClamped(current, 1, anchor);
  }

  Subscription copyWith({
    String? id,
    String? name,
    String? categoryId,
    double? amount,
    double? taxAmount,
    bool clearTax = false,
    String? currency,
    String? description,
    bool clearDescription = false,
    String? startDate,
    String? nextOccurrenceDate,
    String? billingCycle,
    SubscriptionStatus? status,
    String? createdAt,
    String? updatedAt,
    String? cancelledAt,
    bool clearCancelledAt = false,
    int? notificationOffset,
    bool clearNotificationOffset = false,
    String? deletedAt,
    bool clearDeletedAt = false,
    int? version,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      taxAmount: clearTax ? null : taxAmount ?? this.taxAmount,
      currency: currency ?? this.currency,
      description: clearDescription ? null : description ?? this.description,
      startDate: startDate ?? this.startDate,
      nextOccurrenceDate: nextOccurrenceDate ?? this.nextOccurrenceDate,
      billingCycle: billingCycle ?? this.billingCycle,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelledAt: clearCancelledAt ? null : cancelledAt ?? this.cancelledAt,
      notificationOffset: clearNotificationOffset ? null : notificationOffset ?? this.notificationOffset,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
      version: version ?? this.version,
    );
  }
}
