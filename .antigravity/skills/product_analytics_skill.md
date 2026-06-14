# Product Analytics Skill

## Price History Tracking
- **Historical Analysis:** Track item prices over time using `ExpenseItems` entries linked to specific `Items` in Drift.
- **Store Comparison:** Compare prices of identical items across different `Stores` to highlight cheapest purchasing paths.
- **Normalization:** Compare items on a unit-price basis (e.g., cost per gram or cost per milliliter) instead of total package price.

## Spend Comparison (Monthly & Annual)
- **Deterministic Formulas:** Calculations should rely on sum and average operations over SQLite records:
  - Total monthly spend = sum(totalPrice) of active expenses for month.
  - Category budget utilization = (sum(amount) of expenses in category / category budget amount) * 100%.
- **Year-To-Date (YTD) summaries:** Group monthly summaries to show trends, averages, and seasonal spikes.

## Price-vs-Quantity Calculations
- **Unit Price Calculation:** Ensure unit prices are handled carefully:
  - Formula: `unitPrice = totalPrice / quantity`
  - Floating point checks: Handle potential divide-by-zero errors when quantity is empty, null, or zero. Fallback to setting unitPrice equal to totalPrice with a quantity of 1.0.

## Unit Normalization Limits
- **Dimension Matching:** Only normalize units within matching dimensions (e.g., mass to mass: `g` to `kg`; volume to volume: `ml` to `litre`).
- **No Cross-Dimension Conversions:** Do not attempt conversions across dimensions (e.g., converting grams to millilitres) unless product density metadata is explicitly defined.
- **Factor to Base Unit:** Use standard seeding factors:
  - `dozen` -> factor: 12.0 of base `piece`
  - `g` -> factor: 0.001 of base `kg`
  - `ml` -> factor: 0.001 of base `litre`

## Deterministic Insight Rules
- **No Generative AI:** Insights must be generated using deterministic rules rather than generative AI completions.
  - Example: "Your grocery spend in Category X increased by Y% this month due to Z item price increase."
- **Empty States:** Gracefully handle categories or months with zero data. Display clear explanations rather than rendering empty charts or null exceptions.
