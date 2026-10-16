---
type: adr
status: accepted
created: 2026-10-17
updated: 2026-10-17
domain: product
related:
  - "[[Design-System-and-UX]]"
  - "[[Flutter-Conventions]]"
  - "[[Technical-Debt-Registry]]"
---

# ADR-0010: Tonal Material 3 Design System and Single Brand

## Status
Accepted (2026-10-17). Supersedes the "Warm Liquid Glass" language in the previous [[Design-System-and-UX]].

## Context
A UI audit on 2026-10-16 found:
- 1,117 raw colour literals (`Color(0x…)`, `Colors.*`) across 48 files; the theme was bypassed almost everywhere.
- Four card primitives doing one job (`WMGlassSurface` tiers, `FlatCard`, `LiquidGlass`, `WMDarkHeroCard`) plus `FlatNavBar`, and an `AppCard` wrapper over them.
- 11 text sizes in the theme alone (10, 11, 11.5, 12.5, 13, 13.5, 14.5, 15.5, 19, 24, 38), more added ad hoc in screens.
- `textMuted` `#94A3B8` was 2.6:1 on white (WCAG AA needs 4.5:1 for text).
- Brand conflict: this vault said amber `#F59E0B` ("Melt Gold"); the code shipped indigo `#6366F1`; light-mode `primary` was near-black while dark-mode `primary` was indigo.
- Decoration without information: a drawn EMV chip and contactless icon on the dashboard hero.

Three mockup directions were compared (A Tonal, B Ledger, C Bento). User decision (2026-10-17): "Go ahead with tonal and standardize branding, so future work is also coherent."

## Decision
1. **Direction A, Tonal.** Stock Material 3 structure: tonal surface steps instead of borders, shadows and blur; `NavigationBar`, `FloatingActionButton`, filter chips and outlined fields styled through `ThemeData`, not per screen.
2. **One brand: indigo.** The vault's amber is retired. Brand primary is `#4B45C9` (light) / `#BFC2FF` (dark); this resolves the vault/code conflict in favour of the shipped colour. Gold/amber survives only as the *caution* status hue.
3. **Colours come from roles, never literals.** `ColorScheme` carries brand, surface and neutral roles. A `ThemeExtension<WMMoneyColors>` carries money semantics (income, caution, over budget, each with a *fill* and an AA-contrast *text* variant).
4. **One type scale of six steps** in `WMType`: 34 / 22 / 17 / 14 / 12 / 11 (display, headline, title, body, label, caption). Nothing below 11. Font stays Plus Jakarta Sans.
5. **One card primitive, `WMCard`,** with four tones (surface, raised, brand, outlined). `WMGlassSurface`, `FlatCard`, `LiquidGlass`, `WMDarkHeroCard` and `AppCard` remain only as thin compatibility wrappers over `WMCard` and must not be used in new code.
6. **Flat canvas.** `AppBackground` paints the scheme surface; the gradient and glow orbs are removed. No `BackdropFilter`, no decorative skeuomorphism.
7. **Enforcement.** `test/theme/design_token_guard_test.dart` fails if the count of raw colour literals in `lib/src` rises above the recorded baseline, if `WalletMeltColors`/theme files regress, or if a new `fontSize` below 11 appears. The baseline is a ratchet: it may only go down. Migration of the legacy literals is tracked as TD-010.

## Consequences
- Light and dark are two palettes of the same roles; dark uses true black (`#000000`) as canvas.
- Screens not yet migrated keep working through the legacy `WalletMeltColors` constants, whose neutral and brand values now follow the new palette; semantic status constants (`positive`, `warning`, `danger`) keep their fill values so tests and bars stay stable.
- Any new screen or widget must follow [[Design-System-and-UX]]; reviewers reject raw colours and ad hoc font sizes.
- The launcher icon background (`#121218`) is unchanged.
