import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../constants/currencies.dart';
import '../../services/export/expense_csv_export_service.dart';
import '../../services/export/export_share_service.dart';
import '../../services/export/file_picker_service.dart';
import '../../services/export/wallet_melt_json_backup_conflict_service.dart';
import '../../services/export/wallet_melt_json_backup_import_validation_service.dart';
import '../../services/export/wallet_melt_json_backup_preview_service.dart';
import '../../services/export/wallet_melt_json_backup_service.dart';
import '../../services/export/wallet_melt_json_backup_validator.dart';
import '../../services/export/wallet_melt_json_restore_dry_run_planner.dart';
import '../../services/export/wallet_melt_json_restore_service.dart';
import '../../services/export/wallet_melt_json_restore_plan.dart';
import 'backup_restore_dialog.dart';
import 'restore_summary_dialog.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/settings.dart';
import '../../widgets/app_snackbar.dart';
import '../security/create_pin_screen.dart';
import '../security/verify_pin_screen.dart';
import '../../security/pin_lock_controller.dart';
import '../../security/root_detection_service.dart';
import '../../utils/platform_info.dart';



class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    this.expenseCsvExportService = const ExpenseCsvExportService(),
    this.jsonBackupService = const WalletMeltJsonBackupService(),
    this.exportShareService = const SharePlusExportShareService(),
    this.filePickerService = const FilePickerService(),
    this.importValidationService =
        const WalletMeltJsonBackupImportValidationService(),
    this.previewService = const WalletMeltJsonBackupPreviewService(),
    this.conflictService = const WalletMeltJsonBackupConflictService(),
    this.restoreDryRunPlanner = const WalletMeltJsonRestoreDryRunPlanner(),
    this.restoreService = const WalletMeltJsonRestoreService(),
    this.safetyBackupDirectory,
    super.key,
  });

  final ExpenseCsvExportService expenseCsvExportService;
  final WalletMeltJsonBackupService jsonBackupService;
  final ExportShareService exportShareService;
  final FilePickerService filePickerService;
  final WalletMeltJsonBackupImportValidationService importValidationService;
  final WalletMeltJsonBackupPreviewService previewService;
  final WalletMeltJsonBackupConflictService conflictService;
  final WalletMeltJsonRestoreDryRunPlanner restoreDryRunPlanner;
  final WalletMeltJsonRestoreService restoreService;
  final Directory? safetyBackupDirectory;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExportingExpenses = false;
  bool _isCreatingJsonBackup = false;
  bool _includeDeletedExpenses = false;
  bool _isValidatingBackup = false;
  bool _isRestoreInProgress = false;
  RootDetectionResult _rootResult = const RootDetectionResult.clean();

  @override
  void initState() {
    super.initState();
    const RootDetectionService().checkDeviceIntegrity().then((result) {
      if (mounted) {
        setState(() {
          _rootResult = result;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().loadDeletedExpenses();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = context.select((AppState s) => s.settings.currency);
    final themePreference =
        context.select((AppState s) => s.settings.themePreference);
    final lastExportedAt =
        context.select((AppState s) => s.settings.lastExportedAt);
    final expensesLength = context.select((AppState s) => s.expenses.length);
    final deletedExpensesLength =
        context.select((AppState s) => s.deletedExpenses.length);

    return Scaffold(
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            // Top Bar
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Settings',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Standout App Name & Brand Hero Card
            WMGlassSurface.tier1(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/brand/optimized/walletmelt_icon_transparent.webp',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      semanticLabel: 'WalletMelt logo',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              'WalletMelt',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 19,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: WalletMeltColors.brand.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: WalletMeltColors.brand.withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'v1.0',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: theme.brightness == Brightness.dark
                                      ? WalletMeltColors.brand
                                      : WalletMeltColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Offline & Encrypted Financial Manager',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.brightness == Brightness.dark
                                ? WalletMeltColors.darkTextSecondary
                                : WalletMeltColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),


            // SECTION 1: PREFERENCES
            Text(
              'PREFERENCES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: WalletMeltColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            WMGlassSurface.tier1(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    dropdownColor:
                        theme.brightness == Brightness.dark
                            ? WalletMeltColors.darkSurface
                            : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    isExpanded: true,
                    items: [
                      if (!supportedCurrencies.any((c) => c.code == currency) &&
                          currency.isNotEmpty)
                        DropdownMenuItem(
                          value: currency,
                          child: Text(currency,
                              overflow: TextOverflow.ellipsis),
                        ),
                      for (final c in supportedCurrencies)
                        DropdownMenuItem(
                          value: c.code,
                          child: Text(c.displayLabel,
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    selectedItemBuilder: (context) {
                      return [
                        if (!supportedCurrencies
                                .any((c) => c.code == currency) &&
                            currency.isNotEmpty)
                          Text(currency,
                              overflow: TextOverflow.ellipsis, maxLines: 1),
                        for (final c in supportedCurrencies)
                          Text(c.displayLabel,
                              overflow: TextOverflow.ellipsis, maxLines: 1),
                      ];
                    },
                    onChanged: (value) {
                      if (value != null) state.updateCurrency(value);
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ThemePreference>(
                    initialValue: themePreference,
                    decoration: const InputDecoration(labelText: 'Theme'),
                    dropdownColor:
                        theme.brightness == Brightness.dark
                            ? WalletMeltColors.darkSurface
                            : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    items: const [
                      DropdownMenuItem(
                          value: ThemePreference.system, child: Text('System')),
                      DropdownMenuItem(
                          value: ThemePreference.light, child: Text('Light')),
                      DropdownMenuItem(
                          value: ThemePreference.dark, child: Text('Dark')),
                    ],
                    onChanged: (value) {
                      if (value != null) state.updateTheme(value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // SECTION 2: SECURITY & PRIVACY
            Text(
              'SECURITY & PRIVACY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: WalletMeltColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Consumer<PinLockController>(
              builder: (context, pinController, child) {
                final isPinEnabled = pinController.isPinEnabled;
                final isBiometricsAvailable = pinController.isBiometricsAvailable;
                final isBiometricsEnabled = pinController.isBiometricsEnabled;
                final biometricLabel = pinController.biometricLabel;

                return WMGlassSurface.tier1(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_rootResult.isCompromised) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Device Security Notice: System modifications or su binaries were detected. On rooted devices, financial data is exposed to local root processes.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      Material(
                        type: MaterialType.transparency,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'PIN Lock',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Protect WalletMelt with a 4-digit PIN.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: WalletMeltColors.textMuted,
                              ),
                            ),
                          ),
                          value: isPinEnabled,
                          onChanged: (bool value) async {
                            if (value) {
                              final wasSet = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreatePinScreen(),
                                ),
                              );
                              if (wasSet == true) {
                                await pinController.refreshPinStatus();
                              }
                            } else {
                              final verified = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VerifyPinScreen(
                                    title: 'Disable PIN Lock',
                                    instruction: 'Enter your PIN to disable security lock',
                                  ),
                                ),
                              );
                              if (verified == true) {
                                await pinController.disablePin();
                                if (!context.mounted) return;
                                showSuccessSnackbar(context, 'PIN Lock disabled.');
                              }
                            }
                          },
                        ),
                      ),
                      if (isBiometricsAvailable) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, thickness: 0.5),
                        ),
                        Material(
                          type: MaterialType.transparency,
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '$biometricLabel Unlock',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isPinEnabled
                                    ? null
                                    : (theme.brightness == Brightness.dark
                                        ? WalletMeltColors.darkTextSecondary.withValues(alpha: 0.5)
                                        : WalletMeltColors.textSecondary.withValues(alpha: 0.5)),
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                isPinEnabled
                                    ? 'Use device $biometricLabel to unlock faster.'
                                    : '$biometricLabel requires PIN protection to be enabled first.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: WalletMeltColors.textMuted,
                                ),
                              ),
                            ),
                            value: isBiometricsEnabled,
                            onChanged: !isPinEnabled
                                ? null
                                : (bool value) async {
                                    if (value) {
                                      final verified = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => VerifyPinScreen(
                                            title: 'Enable $biometricLabel',
                                            instruction: 'Enter your PIN to setup $biometricLabel',
                                          ),
                                        ),
                                      );
                                      if (verified == true) {
                                        if (!context.mounted) return;
                                        final authResult = await pinController.biometricService.authenticate(
                                          localizedReason: 'Confirm $biometricLabel to enable quick unlock',
                                        );
                                        if (authResult.isSuccess) {
                                          await pinController.setBiometricsEnabled(true);
                                          if (!context.mounted) return;
                                          showSuccessSnackbar(context, '$biometricLabel unlock enabled.');
                                        } else if (authResult.errorMessage != null) {
                                          if (!context.mounted) return;
                                          showErrorSnackbar(context, authResult.errorMessage!);
                                        }
                                      }
                                    } else {
                                      final verified = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => VerifyPinScreen(
                                            title: 'Disable $biometricLabel',
                                            instruction: 'Enter your PIN to disable $biometricLabel unlock',
                                          ),
                                        ),
                                      );
                                      if (verified == true) {
                                        await pinController.setBiometricsEnabled(false);
                                        if (!context.mounted) return;
                                        showSuccessSnackbar(context, '$biometricLabel unlock disabled.');
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
                      if (isPinEnabled) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, thickness: 0.5),
                        ),
                        // ── Change PIN Row ──────────────────────────────────
                        Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final verified = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VerifyPinScreen(
                                    title: 'Verify PIN',
                                    instruction: 'Enter current PIN to change it',
                                  ),
                                ),
                              );
                              if (verified == true) {
                                if (!context.mounted) return;
                                final wasChanged = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CreatePinScreen(),
                                  ),
                                );
                                if (wasChanged == true) {
                                  if (!context.mounted) return;
                                  showSuccessSnackbar(context, 'PIN changed successfully.');
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: WalletMeltColors.brand.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.pin_outlined,
                                      size: 20,
                                      color: WalletMeltColors.brand,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Change PIN',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Update your 4-digit security code.',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: WalletMeltColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Divider(height: 1, thickness: 0.5),
                        ),
                        // ── Disable PIN Lock Row ────────────────────────────
                        Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final verified = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VerifyPinScreen(
                                    title: 'Disable PIN',
                                    instruction: 'Enter your PIN to disable the lock',
                                  ),
                                ),
                              );
                              if (verified == true) {
                                await pinController.disablePin();
                                if (!context.mounted) return;
                                showSuccessSnackbar(context, 'PIN Lock disabled.');
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.lock_open_rounded,
                                      size: 20,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Disable PIN Lock',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.error,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Turn off PIN and biometric protection.',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: WalletMeltColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Divider(height: 1, thickness: 0.5),
                      ),
                      // ── Privacy Policy & Disclaimer Row ──────────────────
                      Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.push('/privacy-policy'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Privacy Policy & Legal Disclaimer',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Review offline security terms and liability limitations.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: WalletMeltColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                );
              },
            ),
            const SizedBox(height: 28),

            // SECTION 3: PEOPLE & CONTACTS
            Text(
              'PEOPLE & ENTITIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: WalletMeltColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            WMGlassSurface.tier1(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payees & Contacts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage list of people for lending, borrowing, and other people-centric records.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WalletMeltColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/payees'),
                      icon: const Icon(Icons.people_alt_rounded, size: 18),
                      label: const Text('Manage Payees & Contacts'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            WMGlassSurface.tier1(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved Merchants & Places',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage frequent shops, restaurants, and bill vendors for 1-tap category selection.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WalletMeltColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/merchants'),
                      icon: const Icon(Icons.storefront_rounded, size: 18),
                      label: const Text('Manage Saved Merchants'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // SECTION 4: BACKUP & DATA MANAGEMENT
            Text(
              'DATA & BACKUPS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: WalletMeltColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            WMGlassSurface.tier1(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data export subsection
                  Text(
                    'Data export',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Material(
                    type: MaterialType.transparency,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: _includeDeletedExpenses,
                      title: const Text('Include deleted expenses'),
                      onChanged: _isExportingExpenses
                          ? null
                          : (value) {
                              setState(() {
                                _includeDeletedExpenses = value ?? false;
                              });
                            },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isExportingExpenses
                          ? null
                          : () => _exportExpensesCsv(state),
                      icon: _isExportingExpenses
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.ios_share_rounded, size: 18),
                      label: Text(_isExportingExpenses
                          ? 'Preparing CSV'
                          : 'Export expenses CSV'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isCreatingJsonBackup
                          ? null
                          : () => _createJsonBackup(state),
                      icon: _isCreatingJsonBackup
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.backup_outlined, size: 18),
                      label: Text(_isCreatingJsonBackup
                          ? 'Preparing backup'
                          : 'Back up JSON'),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, thickness: 0.5),
                  ),

                  // Data import subsection
                  Text(
                    'Data import',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isValidatingBackup || _isRestoreInProgress
                          ? null
                          : _validateBackupFile,
                      icon: _isValidatingBackup
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restore_outlined, size: 18),
                      label: Text(_isValidatingBackup
                          ? 'Validating...'
                          : 'Validate backup file'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a backup JSON file to verify its structure and compatibility before importing. No changes will be made to your data.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WalletMeltColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _exportStatusText(currency, expensesLength,
                        deletedExpensesLength, lastExportedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: WalletMeltColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // SECTION 5: ABOUT & PRIVACY
            Text(
              'ABOUT WALLETMELT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: WalletMeltColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            WMGlassSurface.tier1(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy First',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All expenses, settings, categories, budgets, and receipt images stay stored locally on this device. There is no remote login, backend databases, or cloud tracking.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WalletMeltColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  Text(
                    'Future Scope',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Automatic cloud synchronization, shared household ledger profiles, OCR-based receipt scanning, and recurring expense reminders are planned for future versions.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WalletMeltColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Version',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'v1.0.0',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: WalletMeltColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _exportExpensesCsv(AppState state) async {
    setState(() => _isExportingExpenses = true);

    try {
      if (_includeDeletedExpenses) {
        await state.loadDeletedExpenses();
      }
      final expenses = _includeDeletedExpenses
          ? [...state.expenses, ...state.deletedExpenses]
          : state.expenses;
      final file = await widget.expenseCsvExportService.exportActiveExpenses(
        expenses: expenses,
        categories: state.categories,
        includeDeleted: _includeDeletedExpenses,
      );
      final shareResult = await widget.exportShareService.shareFile(file);
      if (!mounted) return;

      await state.recordExportedAt(file.createdAt);
      if (!mounted) return;

      final message = switch (shareResult.status) {
        ExportShareStatus.success => 'CSV export shared.',
        ExportShareStatus.dismissed => 'CSV export canceled.',
        ExportShareStatus.unavailable => 'CSV export file is ready.',
      };
      showSuccessSnackbar(context, message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnackbar(context, 'CSV export failed.');
    } finally {
      if (mounted) {
        setState(() => _isExportingExpenses = false);
      }
    }
  }

  Future<void> _createJsonBackup(AppState state) async {
    setState(() => _isCreatingJsonBackup = true);

    try {
      await state.loadDeletedExpenses();
      final file = await widget.jsonBackupService.createBackup(
        expenses: [...state.expenses, ...state.deletedExpenses],
        groceryItems: await state.listAllGroceryItemsForExport(),
        categories: state.categories,
        budgets: await state.listAllBudgetsForExport(),
        settings: state.settings,
      );
      final shareResult = await widget.exportShareService.shareFile(
        file,
        subject: 'WalletMelt JSON backup',
        title: 'Back up WalletMelt data',
      );
      if (!mounted) return;

      await state.recordExportedAt(file.createdAt);
      if (!mounted) return;

      final message = switch (shareResult.status) {
        ExportShareStatus.success => 'JSON backup shared.',
        ExportShareStatus.dismissed => 'JSON backup canceled.',
        ExportShareStatus.unavailable => 'JSON backup file is ready.',
      };
      showSuccessSnackbar(context, message);
    } catch (_) {
      if (!mounted) return;
      showErrorSnackbar(context, 'JSON backup failed.');
    } finally {
      if (mounted) {
        setState(() => _isCreatingJsonBackup = false);
      }
    }
  }

  Future<void> _validateBackupFile() async {
    setState(() => _isValidatingBackup = true);

    try {
      final backupFile = await widget.filePickerService.pickBackupFile();
      if (!mounted) return;

      if (backupFile == null) {
        return;
      }

      final result = (PlatformInfo.isFlutterTest || PlatformInfo.isWeb)
          ? widget.importValidationService.validateBackup(backupFile.jsonText)
          : await compute(_validateBackupIsolate, backupFile.jsonText);
      if (!mounted) return;

      if (result.isValid) {
        final preview = (PlatformInfo.isFlutterTest || PlatformInfo.isWeb)
            ? widget.previewService.generatePreview(backupFile.jsonText)
            : await compute(_generatePreviewIsolate, backupFile.jsonText);
        if (!mounted) return;
        if (preview.isValid) {
          final state = context.read<AppState>();
          await state.loadDeletedExpenses();
          final groceryItems = await state.listAllGroceryItemsForExport();
          final budgets = await state.listAllBudgetsForExport();
          if (!mounted) return;

          final snapshot = LocalAppSnapshot(
            expenses: state.expenses,
            deletedExpenses: state.deletedExpenses,
            categories: state.categories,
            budgets: budgets,
            groceryItems: groceryItems,
            settings: state.settings,
          );

          BackupConflictSummary? conflictSummary;
          RestoreDryRunPlan? dryRunPlan;
          try {
            if (PlatformInfo.isFlutterTest || PlatformInfo.isWeb) {
              conflictSummary = widget.conflictService.detect(
                jsonText: backupFile.jsonText,
                localSnapshot: snapshot,
              );
              dryRunPlan = widget.restoreDryRunPlanner.plan(
                jsonText: backupFile.jsonText,
                localSnapshot: snapshot,
                conflictSummary: conflictSummary,
                mode: RestoreMode.safeMerge,
              );
            } else {
              conflictSummary = await compute(
                _detectConflictsIsolate,
                _ConflictDetectionArgs(backupFile.jsonText, snapshot),
              );
              if (!mounted) return;
              dryRunPlan = await compute(
                _planRestoreIsolate,
                _RestorePlanArgs(
                  jsonText: backupFile.jsonText,
                  localSnapshot: snapshot,
                  conflictSummary: conflictSummary,
                  mode: RestoreMode.safeMerge,
                ),
              );
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Conflict/dry-run detection threw: $e');
            }
          }

          if (!mounted) return;

          _showBackupRestoreDialog(
            backupFile: backupFile,
            preview: preview,
            localSnapshot: snapshot,
            conflictSummary: conflictSummary,
            dryRunPlan: dryRunPlan,
          );
        } else {
          // Fallback snackbar when preview is invalid but validation result is valid (e.g. legacy tests)
          showSuccessSnackbar(
            context,
            'Backup file is valid. Preview found ${result.expensesCount} expenses, '
            '${result.groceryItemsCount} items, ${result.categoriesCount} categories, '
            'and ${result.budgetsCount} budgets. No data has been imported or changed.',
          );
        }
      } else {
        showErrorSnackbar(
          context,
          'Invalid backup file: '
          '${_safeRestoreErrorMessage(result.error ?? "Unknown error")}',
        );
        if (kDebugMode) {
          debugPrint('VALIDATION RESULT INVALID: ${result.error}');
        }
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('VALIDATION EXCEPTION: $e\n$stack');
      }
      if (!mounted) return;
      showErrorSnackbar(
        context,
        'Could not read the selected backup file. No data was changed. '
        '${_safeRestoreErrorMessage(e.toString())}',
      );
    } finally {
      if (mounted) {
        setState(() => _isValidatingBackup = false);
      }
    }
  }

  void _showBackupRestoreDialog({
    required WalletMeltBackupFile backupFile,
    required WalletMeltBackupPreview preview,
    required LocalAppSnapshot localSnapshot,
    BackupConflictSummary? conflictSummary,
    RestoreDryRunPlan? dryRunPlan,
  }) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) {
        return BackupRestoreDialog(
          backupFile: backupFile,
          preview: preview,
          localSnapshot: localSnapshot,
          initialConflictSummary: conflictSummary,
          initialDryRunPlan: dryRunPlan,
          jsonBackupService: widget.jsonBackupService,
          restoreService: widget.restoreService,
          onSuccess: (result, durationSeconds, mode, backupVersion) {
            _showRestoreSummaryDialog(
                result, durationSeconds, mode, backupVersion);
          },
          onRestoreStarted: () {
            setState(() => _isRestoreInProgress = true);
          },
          onRestoreFinished: () {
            setState(() => _isRestoreInProgress = false);
          },
          safetyBackupDirectory: widget.safetyBackupDirectory,
        );
      },
    );
  }

  void _showRestoreSummaryDialog(
    WalletMeltJsonRestoreResult result,
    double durationSeconds,
    RestoreMode mode,
    int backupVersion,
  ) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return RestoreSummaryDialog(
          result: result,
          durationSeconds: durationSeconds,
          mode: mode,
          backupVersion: backupVersion,
        );
      },
    );
  }

  String _safeRestoreErrorMessage(String message) {
    final firstLine = message
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(RegExp(r'[#\n\r]'))
        .first
        .trim();
    var sanitized = firstLine
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^StateError:\s*'), '')
        .replaceFirst(RegExp(r'^SqliteException\(\d+\):\s*'), '')
        .replaceAll(RegExp(r'at package:[^ ]+'), '')
        .trim();
    const maxLength = 180;
    if (sanitized.length > maxLength) {
      sanitized = '${sanitized.substring(0, maxLength).trimRight()}...';
    }
    return sanitized.isEmpty ? 'Unknown restore error.' : sanitized;
  }

  String _exportStatusText(String currency, int expensesLength,
      int deletedExpensesLength, String? lastExportedAt) {
    final activeCount = expensesLength;
    final deletedCount = deletedExpensesLength;
    final countText = _includeDeletedExpenses
        ? '$activeCount active, $deletedCount deleted'
        : '$activeCount active';
    if (lastExportedAt == null || lastExportedAt.isEmpty) {
      return 'Ready to export $countText. Last export: never.';
    }

    return 'Ready to export $countText. Last export: ${_compactTimestamp(lastExportedAt)}.';
  }

  String _compactTimestamp(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    final local = parsed.toLocal();
    return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)} '
        '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _ConflictDetectionArgs {
  final String jsonText;
  final LocalAppSnapshot localSnapshot;
  const _ConflictDetectionArgs(this.jsonText, this.localSnapshot);
}

BackupConflictSummary _detectConflictsIsolate(_ConflictDetectionArgs args) {
  const conflictService = WalletMeltJsonBackupConflictService();
  return conflictService.detect(
    jsonText: args.jsonText,
    localSnapshot: args.localSnapshot,
  );
}

class _RestorePlanArgs {
  final String jsonText;
  final LocalAppSnapshot localSnapshot;
  final BackupConflictSummary? conflictSummary;
  final RestoreMode mode;
  const _RestorePlanArgs({
    required this.jsonText,
    required this.localSnapshot,
    this.conflictSummary,
    required this.mode,
  });
}

RestoreDryRunPlan _planRestoreIsolate(_RestorePlanArgs args) {
  const planner = WalletMeltJsonRestoreDryRunPlanner();
  return planner.plan(
    jsonText: args.jsonText,
    localSnapshot: args.localSnapshot,
    conflictSummary: args.conflictSummary,
    mode: args.mode,
  );
}

BackupValidationResult _validateBackupIsolate(String jsonText) {
  const service = WalletMeltJsonBackupImportValidationService();
  return service.validateBackup(jsonText);
}

WalletMeltBackupPreview _generatePreviewIsolate(String jsonText) {
  const service = WalletMeltJsonBackupPreviewService();
  return service.generatePreview(jsonText);
}
