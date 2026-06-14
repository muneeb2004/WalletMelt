---
name: android_runtime_qa_skill
description: Procedures for managing emulator launches, manual QA smoke tests, checking persistence, and verifying migration states on runtime devices.
---

# WalletMelt Android Runtime QA Skill

## Emulator & Device Management
- **List Devices:** `flutter devices`
- **List Emulators:** `flutter emulators`
- **Launch Emulator:** `flutter emulators --launch <emulator_id>`
- **Run App:** `flutter run`

## Manual Smoke-Test Checklist
Verify the following functions on a running device or emulator:
1. **App Launch & Onboarding:**
   - App boots to onboarding without immediate crash or infinite loading loops.
   - Initial currency setup completes and redirects to Dashboard.
2. **Data Presentation:**
   - Categories load with correct default icons and colors.
   - Monthly budget cards display and show correct values.
3. **Budget Operations:**
   - Setting a budget for a category updates the progress bar immediately.
   - Clearing a budget removes the progress bar.
   - Navigating months (previous/next) reflects correct budget allocations.
4. **Expense Navigation:**
   - Navigating to History displays transaction cards.
   - Tapping an expense card opens the detail sheet with no database-open exceptions.
5. **Persistence Checks:**
   - Restart the app and verify all inputs, categories, and budgets persist.

## Hard Rules
- Runtime QA cannot be marked PASS unless the app successfully boots and runs on a physical device or emulator.
- Document and report any emulator boot crashes or database locks immediately.
