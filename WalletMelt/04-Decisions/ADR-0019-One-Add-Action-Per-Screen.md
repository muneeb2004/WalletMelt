---
type: adr
status: accepted
created: 2026-11-09
updated: 2026-11-09
domain: design
related:
  - "[[Design-System-and-UX]]"
  - "[[ADR-0018-Unified-Modal-Sheet-System]]"
---

# ADR-0019: One add action per screen, empty states are text only

## Context
The Debts tab showed the shell FAB "Add Obligation" and, when empty, an empty-state button "Record Debt or Loan". Both opened the same flow, so two buttons competed. Other screens used differently labelled FABs, and Payees used a plain icon-only one.

## Decision
1. Each screen has at most one add action: the extended FAB, sentence case, verb first ("Add expense", "Add" on Debts, "Add account", "Add income", "Add goal", "Add committee", "Add merchant", "Add contact").
2. Empty states are text only and point at the FAB ("Tap Add to record money lent, borrowed, or split."). They never carry an add button.
3. Where one FAB covers several kinds (Debts), it opens a `WMSheet` chooser.

## Options considered
- Empty state owns the action and the FAB hides while empty.
- App-bar add with no FAB on secondary screens.

## Consequences
The FAB never moves or disappears as data comes and goes. Empty states with an inline call to action elsewhere (budget "Set Budget", essentials "Add First Essential") predate this rule and should be reviewed against it.
