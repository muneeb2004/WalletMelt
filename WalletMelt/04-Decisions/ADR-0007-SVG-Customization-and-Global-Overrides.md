---
type: adr
status: accepted
created: 2026-09-13
updated: 2026-10-27
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

## Amendment 2026-10-27 (c): icon bank, picker, per-category assignment
- **Problem.** Nothing could change which icon a category uses after creation: the repository only had `createCustom`, and the editor rewrote the *artwork* of an icon id for every category sharing it. A category stuck on a wrong or blank icon (for example Food showing the "..." Other icon) had no way out. The raw SVG markup box was also not user friendly.
- **Per-category assignment.** `DriftCategoryRepository.updateDetails` / `AppState.updateCategory` change a category's name, icon and colour (default categories included; ids never change, so expenses, budgets and templates stay linked). No schema change.
- **Icon bank.** `lib/src/components/category/icon_catalog.dart` holds the catalog: 69 preset icons (28 new) plus the 9 standard icons, each with a group (Food, Transport, Bills, Home, Shopping, Health, Education, Money, Leisure, Family, More) and search keywords. `categoryPresets` keeps its meaning (preset folder only); `pickerCatalog` adds the standard icons for the picker. Existing ids resolve exactly as before. Emoji are a second source, stored as `emoji:<glyph>` and rendered by `CategoryIcon`.
- **Picker.** `showIconPicker` (`lib/src/widgets/icon_picker_sheet.dart`): tabs Icons / Emoji / Yours, search over labels and keywords, "Suggested for you" from the category name, and a pinned "Upload your own SVG" button. Uploads go through `pickAndSaveSvg` (`lib/src/services/svg/svg_upload.dart`) which validates with `SvgSafeguardService` and shows plain-language errors.
- **Editing surfaces.** `showCategoryEditor` (create and edit) is used by the add-expense form (long-press a category chip edits it) and by the new Categories screen (`/categories`, Settings > Categories). The old inline icon grid and upload code in `add_expense_screen.dart` are gone.
- **Raw code removed.** The Advanced markup text box is deleted from `SvgEditorDialog`; the manager banner about editing code is gone. "Replace from file" is now "Replace with my own file".
- **Icon library screen.** `SvgManagerScreen` (`/settings/icons`, labelled "Icon library") lists icons with All / Built in / Yours filters, upload, tweak (colour, shape) and delete of uploads. `AppState.deleteUploadedIcon` repoints categories using a deleted upload to `other` before removing the file. Uploads are named "My icon N" by file modified time, so an upload that is edited later moves to the end and is renumbered (a stable name store is a possible follow-up).
- **Known gaps.** Multicolour uploads (resolved 2026-10-27): `CategoryIcon` skips the tint when `SvgColourInfo.isMulticolour` (`lib/src/services/svg/svg_colour_info.dart`) finds two or more distinct fixed colours or a gradient/image, so logos keep their colours; single-colour uploads still follow the theme; (resolved 2026-10-27: ZIP backups now carry `custom_icons/` and overrides, see [[Backup-Format-Specification]] section 10); raster (PNG/JPG) uploads are not supported.
- **Tests.** `test/components/icon_catalog_test.dart` (assets exist and pass the safeguard, unique ids, legacy ids kept), `test/widgets/icon_picker_sheet_test.dart`, repository tests for `updateDetails` and `replaceIcon`, updated manager and editor tests.
