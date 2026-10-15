---
type: work-tracker
status: active
priority: high
created: 2026-09-13
updated: 2026-10-15
domain: work
related:
  - "[[Current-Project-State]]"
---

# Active Work & Roadmap Registry

## Now (Current Release v1.1.2)
- [x] Across-the-board SVG customization & live override reflection (`v1.1.2`).
- [x] Deterministic financial metrics engine (`FinancialMetricsCalculator`).
- [x] Explicit metric calculations transparency menu in Settings.
- [x] Standardized 5-target release APK compilation & verification.
- [x] Establish Obsidian vault engineering control plane.

## Next (Upcoming Incremental Refinements)
- [ ] Investigate Kotlin Gradle Plugin (KGP) warnings in `flutter_image_compress_common` and `share_plus` when upstream updates release.
- [ ] Add selective conflict resolution UI for manual category/budget choice during backup restore.
- [ ] Add compressed ZIP media archiving for receipt photos during backup.

## Later (Future Architectural Horizons - V3 Roadmap)
- [ ] Monorepo Turborepo backend foundation (NestJS / PostgreSQL 16 / Prisma).
- [ ] Cloud sync metadata transport layer (`sync_metadata` integration).
- [ ] Receipt OCR processing queue with Google Document AI / BullMQ.
- [ ] Multi-device Web/Desktop client access.

## Blocked
- *None currently.*

## Added 2026-10-15
- **Now**: Resolve TD-007 (commit `app_version.dart`) and decide TD-004 (fullReplace).
- **Next**: Validate student strategy via interviews ([[Student-Market-Strategy]] §6); draft ADR proposals for income inflows, semester budgets, student categories.
- **Later**: Backup coverage for all domains (TD-005); localization foundation (TD-008).
