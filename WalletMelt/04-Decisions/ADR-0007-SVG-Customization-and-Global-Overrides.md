---
type: adr
status: accepted
created: 2026-09-13
updated: 2026-09-13
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
