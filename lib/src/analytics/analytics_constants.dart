/// Centralized analytics thresholds, stability bands, pacing constraints,
/// and proportional taxonomy multipliers for WalletMelt Insights.
class AnalyticsConstants {
  AnalyticsConstants._();

  /// Currency-specific minimum meaningful amount threshold.
  /// Invariant: All Expense.amount values are assumed denominated in Settings.currency for V1.
  static double minimumMeaningfulAmount(String currency) {
    return switch (currency.toUpperCase()) {
      'PKR' => 500.0,
      'INR' => 200.0,
      'BDT' => 200.0,
      'LKR' => 500.0,
      'NPR' => 300.0,
      'AFN' => 200.0,
      'JPY' => 500.0,
      'KRW' => 5000.0,
      'VND' => 100000.0,
      'IDR' => 50000.0,
      'IRR' => 100000.0,
      'IQD' => 5000.0,
      'LBP' => 50000.0,
      'UZS' => 50000.0,
      'KZT' => 2000.0,
      'NGN' => 3000.0,
      'USD' => 5.0,
      'EUR' => 5.0,
      'GBP' => 5.0,
      'CAD' => 5.0,
      'AUD' => 5.0,
      'CHF' => 5.0,
      'NZD' => 5.0,
      'SGD' => 5.0,
      'AED' => 20.0,
      'SAR' => 20.0,
      'QAR' => 20.0,
      'OMR' => 2.0,
      'BHD' => 2.0,
      'KWD' => 2.0,
      'TRY' => 100.0,
      'MYR' => 20.0,
      _ => 5.0,
    };
  }

  /// Minimum percentage change threshold to distinguish stable frequency metrics.
  static const double frequencyStabilityBandPercent = 10.0;

  /// Minimum percentage change magnitude to surface a standalone category change item.
  static const double minCategoryChangePercent = 10.0;

  /// Minimum calendar days elapsed before calculating pace/velocity.
  static const int minDaysForVelocity = 7;

  /// Minimum positive expenses recorded in current month for velocity calculation.
  static const int minExpensesForVelocity = 5;

  /// Budget usage thresholds for risk escalation.
  static const double budgetInfoThreshold = 0.60;
  static const double budgetWarningThreshold = 0.80;
  static const double budgetAlertThreshold = 0.95;

  /// Minimum positive transactions at a merchant before checking category consistency.
  static const int minPositiveTransactionsForInconsistency = 3;

  /// Maximum insight cards displayed in the ranked feed for V1.
  static const int maxRankedInsights = 7;

  /// Proportional taxonomy weight multipliers (no artificial clamping floors).
  static const double riskTaxonomyMultiplier = 1.4;
  static const double behavioralTaxonomyMultiplier = 1.0;
  static const double structureTaxonomyMultiplier = 0.8;
}
