---
name: product_analytics_skill
description: Formulas and limits for price history comparisons, unit normalizations, and deterministic spending analysis.
---

# WalletMelt Product Analytics Skill

## V2 Spend Analysis & Calculations
Ensure spending intelligence features adhere to the following mathematical specifications:

### Price-vs-Quantity (Spend Effects) Formula
To explain differences in spending between two periods for an item:
- **Base Period:**
  - Quantity ($Q_1$), Unit Price ($P_1$), Total Spend ($S_1 = Q_1 \times P_1$)
- **Comparison Period:**
  - Quantity ($Q_2$), Unit Price ($P_2$), Total Spend ($S_2 = Q_2 \times P_2$)
- **Spending Change:**
  $$\Delta S = S_2 - S_1$$
- **Price Effect:**
  $$\text{Price Effect} = Q_1 \times (P_2 - P_1)$$
- **Quantity Effect:**
  $$\text{Quantity Effect} = (Q_2 - Q_1) \times P_2$$
- **Identity Check:** Ensure $\text{Price Effect} + \text{Quantity Effect}$ matches $\Delta S$ (adjusted for rounding/remainder if applicable).

## Unit Normalizations & Limits
- **Matches:** Normalize only within matching dimensions (mass-to-mass or volume-to-volume).
- **Factors:**
  - dozen -> 12.0 of base `piece`
  - g -> 0.001 of base `kg`
  - ml -> 0.001 of base `litre`
- **Typo Typos (Aliases):** Map names and normalized aliases to standard item catalog identifiers (e.g., "Bananas" and "Banana" map to the canonical item banana).

## Hard Rules
- All insights must be calculated deterministically. Do NOT generate open-ended text using LLMs or third-party APIs at runtime.
- OCR scanning, cloud synchronization, SMS scrape triggers, and full bills lifecycle management are out of V2 scope (deferred to V2.1).
