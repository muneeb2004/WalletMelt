---
type: product
status: stable
priority: high
created: 2026-09-13
updated: 2026-10-17
domain: product
related:
  - "[[Product-Requirements]]"
  - "[[ADR-0010-Tonal-Material3-Design-System-and-Brand]]"
  - "[[Flutter-Conventions]]"
---

# Brand and Design System: "Tonal"

Authority for how WalletMelt looks, sounds and is named. Decided in [[ADR-0010-Tonal-Material3-Design-System-and-Brand]]. Code lives in `lib/src/theme/`.

## 1. Brand
- **Name**: WalletMelt, one word, capital W and M. Never "Wallet Melt" or "walletmelt" in UI copy.
- **Brand colour**: indigo. Primary `#4B45C9` (light) and `#BFC2FF` (dark). One accent per screen: the primary action or the hero, not both competing.
- **Personality**: calm, precise, on the user's side. Money is shown exactly; status is explained, never alarmed.
- **Logo and icon** (2026-10-17): a rounded wallet body in primary indigo `#4B45C9` with a lavender `#BFC2FF` droplet melting from its flap, separated by a transparent halo. Source art came from a Gemini render, re-keyed to the exact brand tokens by script (two flat colours, transparent background). Assets: `assets/brand/generated/walletmelt_app_icon_launcher.png` (opaque, legacy and iOS), `walletmelt_app_icon_foreground.png` (transparent adaptive foreground, mark at 50% of the canvas for the circular safe zone), and `assets/brand/optimized/walletmelt_*` (transparent, in-app). Adaptive and launcher background is `#15141A`. Regenerate platform icons with `dart run flutter_launcher_icons`. Do not recolour, outline or add effects.

## 2. Colour roles
Use `Theme.of(context).colorScheme` and `context.money`. Raw hex is forbidden outside `lib/src/theme/`.

| Role | Light | Dark | Use |
|---|---|---|---|
| surface (canvas) | `#FCF8FF` | `#000000` | Screen background |
| surfaceContainer | `#F3EFFA` | `#121118` | Cards, nav bar, lists |
| surfaceContainerHigh | `#E8E3F3` | `#1D1C26` | Raised tiles, icon wells, keys |
| primary | `#4B45C9` | `#BFC2FF` | Filled buttons, FAB, links |
| primaryContainer | `#E1E0FF` | `#24235E` | Hero card, selected chip, nav indicator |
| onSurface / onSurfaceVariant | `#1B1B21` / `#4A4A55` | `#E7E3EC` / `#BDBAC8` | Text, secondary text |
| outlineVariant | `#D8D4E3` | `#2E2D3A` | Hairlines, input borders |
| error | `#BA1A1A` | `#FFB4AB` | Errors, destructive |

**Money colours** (`WMMoneyColors`, via `context.money`): each status has a *fill* for bars, icons and chips, and a *text* variant that meets 4.5:1 on its surface.

| Meaning | Fill | Text (light / dark) |
|---|---|---|
| income, under budget, owed to you | `#10B981` | `#09694A` / `#5FD8A4` |
| caution, 70 to 100 percent of budget | `#F59E0B` | `#7A4F00` / `#F5B335` |
| over budget, you owe | `#EF4444` | `#BA1A1A` / `#FFB4AB` |

Budget thresholds: below 70 percent safe, 70 to 100 percent caution, above 100 percent over. Use `context.money.budget(ratio)` or `budgetProgressColor(ratio)`.

## 3. Typography (Plus Jakarta Sans, tabular figures)
Six steps only. Add no others.

| Step | Size / weight | Theme slot | Use |
|---|---|---|---|
| display | 34 / 800 | `displaySmall` | Hero amount |
| headline | 22 / 800 | `headlineMedium` | Screen titles, big stats |
| title | 17 / 700 | `titleLarge` | Section and dialog titles |
| body | 14 / 500 | `bodyLarge`, `bodyMedium`, `titleMedium`, `titleSmall`, `labelLarge` | Content, buttons, list titles |
| label | 12 / 600 | `bodySmall`, `labelMedium` | Secondary text, chips |
| caption | 11 / 600 | `labelSmall` | Metadata, nav labels. Minimum size. |

## 4. Shape, space, depth
- 4pt spacing scale (`AppSpacing`). Radii 12 (chips), 16 (controls), 24 (cards, sheets), 999 (pills).
- **Depth is tonal.** Higher surface step means more important. No drop shadows, no blur, no gradients. Hairline borders only on outlined cards, inputs, sheets and dialogs.
- Touch targets at least 48dp.

## 5. Components
- **`WMCard`**: the only card. Tones: `surface`, `raised`, `brand`, `outlined`. Legacy `WMGlassSurface`, `FlatCard`, `LiquidGlass`, `WMDarkHeroCard`, `AppCard` wrap it for compatibility; do not use them in new code.
- **Navigation**: Material 3 `NavigationBar` with four destinations: Home, History, Planning, Debts. Contextual add action is a `FloatingActionButton.extended`.
- **Buttons**: one filled button per view; others outlined or text. Chips use the themed `FilterChip`.
- **Hero card**: `WMCard(tone: brand)` with the amount in display style, a delta chip, budget bar, remaining, and daily allowance. No decorative elements.

## 6. Voice and copy
- Sentence case for buttons, titles and labels: "Add expense", not "Add Expense". Proper nouns excepted.
- Buttons start with a verb, one to three words. Errors say what happened and what to do, with no "Error:" prefix.
- Avoid "please", "successfully", exclamation marks, and "Click here". Empty states teach the next action.
- Currency amounts use `formatMoney` and tabular figures; the symbol is smaller than the number in hero amounts.

## 7. UX rules (unchanged)
1. **Zero-friction entry**: amount and category are enough to save; everything else is progressive disclosure.
2. **Empty states** teach the next action.
3. **Destructive operations** (permanent delete, restore backup, reset PIN) always confirm.

## 8. Navigation architecture
`StatefulShellRoute.indexedStack` with Home (`/`), History (`/history`), Planning (`/planning`), Debts (`/debt`); full-screen routes for add/edit expense, receipt, settings, PIN lock. See [[Current-Project-State]].

## 9. Rules for future work
- Start every screen from `Scaffold` plus `AppBackground`, consume `colorScheme`, `context.money`, `textTheme` and `AppSpacing`.
- Need a new colour or text size? Propose a role here and in `lib/src/theme/` first; do not inline it.
- The guard test `test/theme/design_token_guard_test.dart` enforces a ratchet on raw colours and small fonts; lower its baseline when you migrate code, never raise it.
- Intentional raw colours: category/user-picked colours, colour-picker and SVG-editor swatches, receipt-viewer image overlay, and white foreground on category-coloured swipe actions.
