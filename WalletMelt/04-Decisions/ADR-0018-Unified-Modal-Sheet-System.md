---
type: adr
status: accepted
created: 2026-11-09
updated: 2026-11-09
domain: design
related:
  - "[[Design-System-and-UX]]"
  - "[[ADR-0010-Tonal-Material3-Design-System-and-Brand]]"
---

# ADR-0018: One modal shell, the edge sheet

## Context
Forms were edge bottom sheets (`showAppBottomSheet`) but confirmations were stock centered `AlertDialog`s, and a few screens still called raw `showDialog` with their own button styles. Header, close button and footer differed per screen.

## Decision
1. Every modal is an edge-attached bottom sheet shown through `showAppBottomSheet` (drag handle, safe area, keyboard avoidance, `AppMotion` entrance).
2. Content uses `WMSheet` (`lib/src/widgets/wm_sheet.dart`): optional icon tile, `titleLarge` title, optional subtitle, scrollable body, sticky footer of equal-width `WMSheetButton`s (48 high, pill, Cancel on the left).
3. `showConfirmDialog` keeps its signature but renders a compact `WMSheet` with an icon tile; destructive confirms turn the icon tile and the action red, nothing else. New optional `icon` parameter.
4. Titles and buttons are sentence case, verb first.

## Exceptions
- Receipt viewer details sheet: a glass overlay on a dark photo, deliberately different.
- Add-expense, goals, settings and SVG editor dialogs with text fields or pickers are still `showDialog` and migrate later.

## Consequences
Change a confirmation's look once, in `wm_sheet.dart`. Dismissing a confirm by drag or scrim returns `null`, same as before.
