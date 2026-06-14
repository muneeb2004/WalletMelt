# Android Runtime QA Skill

## Emulator & Device Management
- **List Available Devices:**
  ```powershell
  flutter devices
  ```
- **List Installed Emulators:**
  ```powershell
  flutter emulators
  ```
- **Launch Emulator:**
  ```powershell
  flutter emulators --launch <emulator_id>
  ```

## Runtime Execution
- **Run in Debug Mode:**
  ```powershell
  flutter run -d <device_id>
  ```
- **Run in Release Mode:**
  ```powershell
  flutter run --release -d <device_id>
  ```

## Manual Smoke-Test Checklist
1. **Onboarding Flow:**
   - Launch app on clean install.
   - Confirm Onboarding slide-through works.
   - Pick default currency and tap "Get Started".
   - Verify redirection to Dashboard and check that default categories (Food, Utilities, etc.) are loaded.
2. **Expense CRUD Operations:**
   - Add a new expense (amount, category, description).
   - Edit the newly created expense.
   - Soft-delete the expense and confirm it moves to history's trash section.
   - Restore the expense and verify it displays on the main Dashboard again.
3. **Category Budgets:**
   - Go to Settings -> Budgets, and set a category budget.
   - Check that Dashboard progress bars and Insights charts update correctly.
   - Delete the budget and verify the visual progress bars disappear.
4. **Receipt Handling:**
   - Attach a receipt image to an expense (using mockup image/photo).
   - View the expense details page and confirm the receipt displays.
   - Permanently delete the expense and confirm the receipt file is deleted from local storage.

## Persistence & State Checks
- **Restart Test:** Exit and relaunch the app. Check that all entered transactions, custom categories, and budgets persist.
- **Theme Preferences:** Toggle settings between light, dark, and system modes to verify visual transitions occur cleanly.
