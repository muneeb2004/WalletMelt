---
type: adr
status: accepted
created: 2026-09-13
updated: 2026-09-13
domain: architecture
related:
  - "[[Analytics-and-Calculations]]"
  - "[[Product-Requirements]]"
---

# ADR-0008: Deterministic Financial Metrics Engine & Transparency Menu

## Status
Accepted

## Context
Financial calculations (Days Remaining, Daily Spend Allowance, Spending Velocity, Debt Net Position) were previously scattered across selectors, resulting in minor edge-case discrepancies (e.g. how the current active calendar day is counted). Users requested verified mathematics and explicit in-app transparency explaining how metrics are calculated.

## Decision
1. Unify all core mathematical formulas inside a centralized, pure-Dart engine: [`FinancialMetricsCalculator`](file:///d:/TechProjects/WalletMelt/lib/src/analytics/financial_metrics_calculator.dart).
2. Explicitly include the active day in Daily Allowance: `Days Remaining = (Last Day of Month) - (Current Day) + 1` to prevent artificial allowance compression.
3. Automatically zero-out allowance when spending exceeds budget.
4. Add [`MetricCalculationsScreen`](file:///d:/TechProjects/WalletMelt/lib/src/screens/settings/metric_calculations_screen.dart) in Settings detailing mathematical formulations with real-time numbers from the user's active budget and spending.

## Alternatives Considered
1. **Excluding current calendar day from Days Remaining**: Rejected because money spent today would be divided over fewer future days, causing a severe artificial reduction in remaining allowance.
2. **Floating-point percentage calculations without threshold clamping**: Rejected because boundary states (e.g. 99.9% vs 100%) caused visual flickering.

## Consequences
- **Positive**: 100% mathematical consistency, 18 automated unit tests verifying edge cases (leap years, month boundaries, over-budget), complete user transparency.
- **Negative**: Additional documentation maintenance when new metrics are formulated.

## Related Code
- `lib/src/analytics/financial_metrics_calculator.dart`
- `lib/src/screens/settings/metric_calculations_screen.dart`
- `test/analytics/financial_metrics_calculator_test.dart`
