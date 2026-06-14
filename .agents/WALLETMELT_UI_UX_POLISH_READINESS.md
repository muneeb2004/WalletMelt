# WalletMelt UI/UX Polish Readiness Checklist

This document guides the transition into UI/UX visual polish phases. It defines architecture requirements, layout safe zones, visual priorities, and verification checklists.

---

## 1. Architecture Migration Stability Checklist

Before starting any visual or layout overhaul, verify the following database and state-management prerequisites are met:

- [ ] **Phase 4 Verification:** Category and Budget runtime read migrations are stable and passing regression test cycles.
- [ ] **Expense CRUD Migration Status:** The migration of expense writing and updating (Phase 5) from sqflite to Drift repositories is complete or isolated such that state flows are well-defined.
- [ ] **No Active Database Work:** No migrations or schema updates are currently being written.
- [ ] **Automated Tests:** `flutter test` completes successfully with zero failures.
- [ ] **Static Analysis:** `flutter analyze` reports zero errors and zero warnings.

---

## 2. File Zones for UI/UX Polish

### Safe Zones (Safe to edit for UI/UX improvements)
These folders contain layout, style, and presentation code that can be modified to improve visuals:
- [lib/src/screens/dashboard/](file:///D:/Web%20Projects/WalletMelt/lib/src/screens/dashboard/)
- [lib/src/screens/history/](file:///D:/Web%20Projects/WalletMelt/lib/src/screens/history/)
- [lib/src/screens/insights/](file:///D:/Web%20Projects/WalletMelt/lib/src/screens/insights/)
- [lib/src/screens/settings/](file:///D:/Web%20Projects/WalletMelt/lib/src/screens/settings/)
- [lib/src/screens/add_expense/](file:///D:/Web%20Projects/WalletMelt/lib/src/screens/add_expense/)
- [lib/src/screens/onboarding/](file:///D:/Web%20Projects/WalletMelt/lib/src/screens/onboarding/)
- [lib/src/components/](file:///D:/Web%20Projects/WalletMelt/lib/src/components/) (UI elements, cards, navigation shells)
- [lib/src/theme/](file:///D:/Web%20Projects/WalletMelt/lib/src/theme/) (Design tokens, text themes)

### Danger Zones (Do NOT touch during UI/UX polish)
These folders control database layers and business state, and must not be touched during styling phases:
- [lib/src/data/](file:///D:/Web%20Projects/WalletMelt/lib/src/data/) (Drift schema, SQL scripts, repository layers)
- [lib/src/state/](file:///D:/Web%20Projects/WalletMelt/lib/src/state/) (`AppState` core ChangeNotifier coordinator)
- [lib/src/providers/](file:///D:/Web%20Projects/WalletMelt/lib/src/providers/) (Riverpod database and business logic providers)
- [lib/src/types/](file:///D:/Web%20Projects/WalletMelt/lib/src/types/) (Immutable business models)
- [lib/src/services/](file:///D:/Web%20Projects/WalletMelt/lib/src/services/) (Local storage, settings storage, file managers)

---

## 3. Visual Priorities & Design Philosophy

Visual improvements should focus on giving the app a premium feel while maintaining high usability:

- **Premium but Usable:** Use card structures, rounded corners, subtle shadows, and glassmorphic designs (liquid-glass theme styling) without adding unnecessary animations that slow down the user.
- **Better Spacing & Hierarchy:** Standardize padding and margins around elements. Ensure primary actions (e.g., adding an expense, saving a budget) stand out.
- **Dashboard Clarity:** Focus on card layout density. The user should see their monthly total spend, budget progress bars, and recent transactions at a glance without scrolling.
- **Insight Density:** Present spending trends and category charts cleanly. Ensure labels do not overlap on smaller screen form-factors.
- **Better Category/Budget Presentation:** Render budget progression bars that change color (e.g., green to amber to red) as expenses approach budget limits.
- **Strong Empty States:** When a category has no expenses or a search returns no matches, display custom illustrations, clean icons, or friendly guidance rather than leaving screens blank.
- **Accessible Contrast:** Ensure text colors satisfy WCAG AA contrast standards.
- **No Clutter:** Avoid purely decorative changes that reduce readability, hide data, or increase scrolling effort.

---

## 4. Screen-by-Screen Polish Checklist

### Dashboard Screen
- [ ] Align top header elements (month selector and currency indicator).
- [ ] Review spend card elevation, color gradients, and layout density.
- [ ] Standardize the spacing around category budget progress bars.
- [ ] Add touch states (hover, press) to the quick-add buttons and expense list cards.

### History Screen
- [ ] Style the expense search input bar with clean borders and active colors.
- [ ] Design a clear layout separating transaction entries by date group headers.
- [ ] Polish soft-deleted indicator badges and swipe action feedback transitions.
- [ ] Polish the layout of the trash folder/archive page.

### Insights Screen
- [ ] Standardize grid structures for expense charts and trend graphs.
- [ ] Add empty states for months without transactions.
- [ ] Polish legends, hover tooltips, and category detail lists.

### Add/Edit Expense Screen
- [ ] Style the numeric amount input field with large typography and clean focus states.
- [ ] Polish the list of categories: ensure category buttons display icons and colors clearly.
- [ ] Improve spacing inside form inputs (Title, Vendor, Notes).
- [ ] Design the receipt attachment widget: display image thumbnails clearly with quick-remove buttons.
- [ ] Improve the layout of the itemized grocery editor (units, quantity, cost fields).

### Settings Screen
- [ ] Standardize settings menu options using list tiles with clear prefix icons and chevron trailing arrows.
- [ ] Style selector dropdowns (Currency selection, Theme choice).
- [ ] Add confirmation alerts with styled action buttons when triggering database resets or database restores.

---

## 5. Post-UI Polish Verification Checklist

After editing visual files, run the following verification steps:

- [ ] **Compile Success:** The project compiles successfully on Android without styling exceptions.
- [ ] **No Logic Breakages:** Tap actions (saving forms, editing fields, toggling themes) execute their underlying actions correctly.
- [ ] **Theme Mode Validation:** Verify that elements switch cleanly between Light Mode and Dark Mode.
- [ ] **Layout Checks:** Verify that form fields and lists do not overflow on smaller screen sizes.
- [ ] **Test Execution:** Run `flutter test` to ensure that visual edits have not broken widget tests.
