---
type: adr
status: accepted
created: 2026-09-13
updated: 2026-10-17
domain: architecture
related:
  - "[[Application-Architecture]]"
  - "[[Flutter-Conventions]]"
---

# ADR-0007: SVG Customization with Global Real-Time Overrides

## Status
Accepted

## Context
Users requested the ability to modify existing category icon SVGs (colors, markup) and upload custom icons, with the requirement that changes reflect across all category chips, cards, and screens immediately without requiring an application restart.

## Decision
1. Implement `SvgCustomizationService` singleton managing disk overrides in `custom_icons/overrides/<id>.svg`.
2. Wrap `CategoryIcon` in a `ListenableBuilder` listening to `SvgCustomizationService.instance`.
3. Provide synchronous file access fallbacks for cache reads to eliminate isolate event loop freezes in Flutter widget testing.
4. Add `SvgManagerScreen` and `SvgEditorDialog` for live previews, quick palette colors, and XML editing.

## Alternatives Considered
1. **Storing SVG XML directly in database table**: Rejected because file-based caching integrates natively with `flutter_svg` and allows direct asset replacement without schema churn.
2. **AppState Rebuild on Every Icon Edit**: Rejected because notifying the entire global `AppState` triggers excessive widget tree rebuilds compared to localized `ListenableBuilder` listeners.

## Consequences
- **Positive**: Real-time icon updating across the board, persistent across launches, reset-to-default support.
- **Negative**: Requires disk I/O management and careful synchronization in test environments.

## Related Code
- `lib/src/services/svg/svg_customization_service.dart`
- `lib/src/components/category/category_icon.dart`
- `lib/src/screens/settings/svg_manager_screen.dart`
- `lib/src/screens/settings/svg_editor_dialog.dart`

## Amendment 2026-10-17: modify tools and a larger default library
- **Modify tools.** `SvgEditOps` (`lib/src/services/svg/svg_edit_ops.dart`) is a pure set of edits on SVG text: tint (works on `currentColor` icons, which the old regex tint did not), theme colour, line weight (0.5 to 3), outline/filled, rotate, flip, zoom, reset position. Geometry edits compose onto one `<g id="wm-transform">` so repeated edits never nest. Every result still goes through `SvgSafeguardService` before saving.
- **Editor.** `SvgEditorDialog` gains a Modify section (undo and redo with 50 steps, the operations above, a line-weight slider) and "Save as new", which stores the modified markup as a new custom icon via `SvgCustomizationService.createCustomIcon` and leaves the original untouched. File replacement is undoable.
- **Default library.** 29 more preset icons (41 presets in total) in the same Lucide-style 24x24 stroke format: coffee, mobile, books, stationery, clothing, medicine, insurance, subscriptions, tax and fees, charity, cash, bike, bus, ride, flights, hotel, movies, music, games, haircut, bank, cards, wallet, bills, tech, printing, garden, hostel, kids. They appear in the preset picker (`categoryPresets`) and the SVG manager. Attribution is in `assets/icons/LICENSE-LUCIDE.txt`.
- **Tests.** `test/services/svg_edit_ops_test.dart` covers each operation, safeguard compatibility, preset registration, uniqueness and rendering.
- **Built-in icons are editable, and edits reach default categories.** Standard and preset icons can be modified like custom ones; "Reset Default" restores the bundled asset. Default categories store Material-style aliases (`bolt`, `wifi`, `water_drop`, `home`, `build`, `local_gas_station`, `local_fire_department`, `shopping_basket`, `more_horiz`). `normalizeKey` now maps these to the built-in id (`electricity`, `internet`, ...), so one override serves both; before 2026-10-17 an edit made in the manager did not reach categories that used the alias.

## Amendment 2026-10-17 (b): startup load, namespace and tint fixes
- **Overrides load at startup.** `SvgCustomizationService.initialize()` was only reached through the manager screen, so after a restart category tiles showed stock artwork while the editor (which reads the file) showed the edit. `appStateProvider` now awaits `initialize()` before the first tile renders; it is idempotent and concurrency-safe, re-validates each stored override and notifies listeners.
- **Namespace kept.** `SvgSafeguardService` no longer strips `xmlns` and `xmlns:*` (their values start with `http://` and were removed by the remote-URL rule), and adds `xmlns` to markup that lacks it. Overrides saved by older builds are healed on load. Remote `href` values are still removed.
- **Edited tint survives.** `CategoryIcon` renders overrides with `SvgTheme(currentColor)` instead of a blanket `srcIn` filter, so a colour baked in by the editor is no longer erased; `currentColor` artwork still follows the surrounding colour.
- **Editor overhaul.** `SvgEditorDialog` is a full-screen editor: header with close, undo/redo and one primary Save; menu with Save as copy, Reset to original (only when edited) and Replace from file; sections for Style (colour, fill, line weight), Transform (rotate, flip, size, reset position) and a collapsed Advanced markup editor; previews at 24/40/64 on light and dark surfaces; a Discard changes confirm when dirty. It always opens editable from the effective SVG. The title is the library icon name and a `Used by: <categories>` line (from `usedBy`, resolved in the manager from `AppState.categories`) removes the Food vs Food & Dining confusion. After Save as copy from a category it offers Use for this category and returns the new id. The old bottom-row overflow on edited icons is gone.
