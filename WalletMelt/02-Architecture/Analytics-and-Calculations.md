---
type: architecture
status: stable
priority: high
created: 2026-09-13
updated: 2026-09-13
domain: architecture
related:
  - "[[Product-Requirements]]"
  - "[[ADR-0008-Deterministic-Financial-Metrics-Engine]]"
---

# Analytics and Calculations

## 1. Deterministic Financial Mathematical Engine
All financial metrics are calculated via [`FinancialMetricsCalculator`](file:///d:/TechProjects/WalletMelt/lib/src/analytics/financial_metrics_calculator.dart) to guarantee mathematical consistency across Dashboard, Budget, Planning, and Settings screens.

### Core Mathematical Formulations:

1. **Days Remaining in Month ($D$)**:
   $$\text{Days Remaining} = \text{Total Days in Month} - \text{Current Day} + 1$$
   *(The $+1$ ensures the active calendar day is included, preventing artificial allowance compression).*

2. **Daily Spend Allowance ($A$)**:
   $$A = \begin{cases} \frac{\text{Remaining Budget}}{D} & \text{if Remaining Budget} > 0 \text{ and } D > 0 \\ 0.00 & \text{if Over Budget or No Budget Set} \end{cases}$$

3. **Budget Utilization Percentage ($U$)**:
   $$U = \left( \frac{\text{Total Month Spent}}{\text{Monthly Budget}} \right) \times 100\%$$
   - $\le 70\%$: Healthy (Positive Green)
   - $70\% - 90\%$: Caution (Warning Orange)
   - $> 90\%$: Danger (Danger Red)
   - $> 100\%$: Over Budget Flag

4. **Spending Velocity & Daily Pace**:
   $$\text{Daily Pace} = \frac{\text{Total Positive Spend}}{\text{Days Elapsed}}$$
   $$\text{Projected Total Spend} = \text{Daily Pace} \times \text{Total Days in Month}$$

5. **Debt & Obligations Position**:
   $$\text{Net Position} = \sum \text{Receivables (Owed To Me)} - \sum \text{Liabilities (I Owe)}$$

6. **Subscription Monthly Normalization**:
   Converts weekly ($\times 52 / 12$), bi-weekly ($\times 26 / 12$), quarterly ($/ 3$), and annual ($/ 12$) commitments into precise 30-day monthly burn rates.
