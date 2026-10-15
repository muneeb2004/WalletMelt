---
type: product
status: proposed
priority: high
created: 2026-10-15
updated: 2026-10-15
domain: product
related:
  - "[[Product-Requirements]]"
  - "[[Gap-Analysis-vs-Code]]"
  - "[[Project-Constitution]]"
---

# Student Market Strategy (Pakistan first, then international)

> **Status: proposed.** Nothing here changes the Stable scope in [[Product-Requirements]]. Items touching the Constitution's out-of-scope list need an ADR first (see §5).

## 1. Objective
Be the best student finance tracker: first for students in Pakistan, then for students anywhere. Differentiator to protect: **offline-first, private, no account** ([[Project-Constitution]] §1).

## 2. Pakistan context (sourced; figures approximate, definitions of "user" differ by source)
- Wallets are mainstream: JazzCash is reported at ~20M+ monthly actives and Easypaisa ~18M; JazzCash skews rural, Easypaisa urban. Raast (SBP instant payments) reported ~496M transactions in 2024. Sources: [Profit/PakistanToday](https://profit.pakistantoday.com.pk/2025/08/16/pakistan-targets-2-million-digital-merchants-120-million-online-banking-users-15-billion-digital-transactions-by-fy26/), [ICMA article](https://icmainternational.com/maj/ma07082025/ma0708_2025-28-30.pdf), [ACE blog](https://acemoneytransfer.com/blog/top-mobile-wallets-in-pakistan) (commercial, low weight).
- Cash still dominates informal/rural spending; distrust of online scams and unstable connectivity are cited barriers ([NSPP journal](https://journal.nspp.gov.pk/index.php/jpa/article/download/131/129/371)). This favours an offline, private tracker.
- Competitive gap (inferred, **not validated**): searches found no widely used, fully Urdu-interface student expense tracker for Pakistan. Monefy wins on fast manual entry but is weak on analytics and paywalls categories; Moneyview/Walnut depend on India-specific SMS/bank parsing; Splitwise-style tools cover splitting. See [Monefy alternatives](https://alternativeto.net/software/monefy--expense-manager), [student app roundup](https://studyinternational.com/news/best-apps-for-budgeting).
- Student behaviour: students plan by **semester** with irregular inflows (allowance, part-time, scholarship) rather than monthly salaries; international students add FX and home-country allowance ([Zolve](https://zolve.com/blog/top-budgeting-apps-for-international-students-and-expats-your-financial-lifeline-abroad/), vendor source). No app clearly models a semester runway. **Needs validation by interviews** (§6).

## 3. What WalletMelt already has that students value
Offline + PIN/biometric lock, receipts, soft-delete, monthly/category budgets, **daily allowance** (core student mechanic), debts/payees (lend/borrow among friends), subscriptions, fuel, backup/restore, PKR default with ~146 currencies. See [[Gap-Analysis-vs-Code]] for the verified gaps.

## 4. Proposed capability themes (ranked by student impact / cost)
| # | Theme | Why (Pakistan → intl) | Constitution impact |
|---|---|---|---|
| 1 | **Income / allowance inflows** (pocket money, stipend, part-time) | Allowance logic is meaningless without inflow; today there is no income table | New schema → migration + ADR |
| 2 | **Semester budget cycle** (period != calendar month; runway to next allowance) | Matches how students plan; unique vs Monefy | Extends MonthlyBudgets → ADR |
| 3 | **Student categories** (tuition, hostel/rent, mess, transport/Careem/Bykea, books, data/mobile load, printing) | Default 9 categories are household-oriented (Electricity, Gas, Rent…) | Seed data only (low risk) |
| 4 | **Payment-method tag** (cash, JazzCash, Easypaisa, Raast/bank, card) | Where money melts; no payment-method column exists | Schema → ADR |
| 5 | **Urdu + Roman Urdu UI, RTL, Urdu digits optional** | Zero l10n today (hardcoded English, no flutter_localizations) | Large cross-cutting change → ADR |
| 6 | **Split with roommates / group trips** | Hostel/shared costs; debts exist but no split model | Schema → ADR |
| 7 | **Committee (BC) / savings goals** | BC is a Pakistani rotating-savings staple; no goals table | New domain → ADR |
| 8 | **Multi-currency for international students** (home allowance + local spend, FX snapshot) | Expenses already store currency; no FX/conversion | ADR |
| 9 | **Lite mode** (low-end Android, small APK, no heavy animation) | Many target devices are low RAM; release APKs are ~50 MB+ | Perf budget |

## 5. Guardrails
- **SMS/notification parsing of JazzCash/Easypaisa alerts** would violate the Constitution's out-of-scope "SMS parsing". Do **not** build it without an approved ADR; consider an opt-in, on-device, permission-gated design and the Play Store SMS-permission policy first.
- No cloud, ads or telemetry. Anything that adds INTERNET permission needs explicit ADR.
- Every theme above starts as an ADR proposal in `04-Decisions/`, then moves to [[Work-Tracker]].

## 6. Validation plan (before building themes 5–8)
5–10 interviews with Pakistani university students (hostel and day-scholars) plus 3–5 international students; test whether semester runway and Urdu UI are top-3 asks. Record results in `06-Knowledge/`.

## 7. Success metrics (proposed)
Day-30 retention, % of users with ≥1 income entry, daily-allowance card views, backup export rate, crash-free sessions on ≤3 GB RAM devices.
