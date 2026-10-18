enum GoalStatus { active, achieved, archived }

GoalStatus goalStatusFromName(String? name) {
  for (final value in GoalStatus.values) {
    if (value.name == name) return value;
  }
  return GoalStatus.active;
}

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetMinorUnits,
    required this.currency,
    required this.accountId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.targetDate,
    this.deletedAt,
  });

  final String id;
  final String name;
  final int targetMinorUnits;
  final String currency;

  /// The account this goal is set aside inside (ADR-0015).
  final String accountId;

  /// ISO date, optional.
  final String? targetDate;
  final GoalStatus status;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  bool get isActive => status == GoalStatus.active;
}

class GoalContribution {
  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.amountMinorUnits,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.deletedAt,
  });

  final String id;
  final String goalId;

  /// Positive sets money aside, negative releases it.
  final int amountMinorUnits;
  final String date;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
}

/// A goal together with its derived saved amount (never stored).
class GoalProgress {
  const GoalProgress({required this.goal, required this.savedMinorUnits});

  final SavingsGoal goal;
  final int savedMinorUnits;

  int get remainingMinorUnits =>
      (goal.targetMinorUnits - savedMinorUnits).clamp(0, 1 << 52);

  bool get isReached => savedMinorUnits >= goal.targetMinorUnits;

  /// 0.0 to 1.0 (clamped) progress toward the target.
  double get fraction => goal.targetMinorUnits <= 0
      ? 0
      : (savedMinorUnits / goal.targetMinorUnits).clamp(0.0, 1.0);
}
