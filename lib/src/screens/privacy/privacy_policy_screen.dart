import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';


/// Screen presenting WalletMelt's Privacy Policy & Legal Disclaimer.
///
/// If [isConsentMode] is true, the user must explicitly accept the terms before
/// entering the application; declining will terminate/exit the app.
/// If [isConsentMode] is false, this acts as a standard in-app reference viewer.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({
    this.isConsentMode = false,
    super.key,
  });

  final bool isConsentMode;

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasAcceptedCheckbox = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onDeclineAndExit() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? WalletMeltColors.darkSurface
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Exit WalletMelt?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Acceptance of the Privacy Policy & Legal Disclaimer is required to use WalletMelt. '
          'Declining will close the application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Review Policy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              if (Platform.isAndroid || Platform.isIOS) {
                SystemNavigator.pop();
              } else {
                exit(0);
              }
            },
            child: const Text('Exit App'),
          ),
        ],
      ),
    );
  }

  Future<void> _onAcceptAndContinue() async {
    await context.read<AppState>().acceptPrivacyPolicy();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !widget.isConsentMode,
      onPopInvokedWithResult: (didPop, result) {
        if (widget.isConsentMode && !didPop) {
          _onDeclineAndExit();
        }
      },
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Top Header App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      if (!widget.isConsentMode) ...[
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: WalletMeltColors.brand.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: WalletMeltColors.brand,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isConsentMode
                                  ? 'Privacy & Terms Notice'
                                  : 'Privacy Policy',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              'Last Updated: August 26, 2026',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: WalletMeltColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Legal & Policy Body
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      children: [
                        // Summary Callout Card
                        WMGlassSurface.tier1(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified_user_rounded,
                                    color: WalletMeltColors.brand,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '100% On-Device & Offline Architecture',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'WalletMelt operates with zero backend servers, zero tracking SDKs, and zero network calls. '
                                'All financial records, receipts, and PINs remain stored exclusively in encrypted SQLite storage on your physical device.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.45,
                                  color: isDark
                                      ? WalletMeltColors.darkTextSecondary
                                      : WalletMeltColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 0: Plain-Language Summary
                        _buildSectionHeader('0. Plain-Language Summary'),
                        _buildParagraph(
                          'WalletMelt does not collect, transmit, or have access to any of your data. '
                          'Everything you enter — expenses, budgets, debts, subscriptions, receipt photos, and your PIN — stays on your device '
                          'in a local encrypted database. The App makes no network connections. There are no accounts, no servers, no analytics, '
                          'and no third parties involved.\n\n'
                          'This also means: if you lose your device, or do not keep your own backups, the Developer cannot recover your data — '
                          'nobody has a copy but you.',
                        ),

                        // Section 1: About This App and the Developer
                        _buildSectionHeader('1. About This App and the Developer'),
                        _buildParagraph(
                          'WalletMelt is a personal expense-tracking application built with Flutter, distributed for Android. '
                          'It is developed and maintained by Sheikh Muhammad Muneeb, an individual, as a personal, hobby project developed in a passive/part-time capacity.\n\n'
                          'WalletMelt is not offered by, and is not affiliated with, any company, corporation, partnership, or other registered legal entity. '
                          'There is no business, no employees, and no organizational structure behind it — only an individual developer.\n\n'
                          'WalletMelt is not a financial institution, does not hold, transmit, or have custody of funds, and is not licensed or regulated '
                          'as a financial services provider in any jurisdiction. It is a personal tracking and budgeting tool only.',
                        ),


                        // Section 2: What Data the App Handles, and Where It Lives
                        _buildSectionHeader('2. What Data the App Handles, and Where It Lives'),
                        _buildParagraph(
                          '2.1 Local-only architecture:\n'
                          'WalletMelt operates with zero backend infrastructure, zero cloud services, and zero network calls. '
                          'The App does not request the Android INTERNET permission and makes no connections to any server, API, or third party.\n\n'
                          'All data you create — expenses, categories, notes, budgets, debt and subscription records, attached receipt photos, '
                          'and PIN hashes (PBKDF2-HMAC-SHA256 with 100,000 iterations) — is stored exclusively on your device with hardware-backed '
                          'Android Keystore integration.\n\n'
                          '2.2 Permissions requested and purpose:\n'
                          '• Camera: To let you photograph receipts and attach them locally to expenses.\n'
                          '• Storage / Media: To let you export and import encrypted backup files.\n'
                          '• Biometric hardware: To let you unlock the App using Android OS biometric APIs.\n\n'
                          '2.3 No third-party services:\n'
                          'The App integrates no analytics SDKs, crash-reporting SDKs, advertising networks, or third-party trackers.',
                        ),

                        // Section 3: Backups and Exports
                        _buildSectionHeader('3. Backups and Exports'),
                        _buildParagraph(
                          'WalletMelt allows you to export your data as an encrypted backup file (AES-256 CTR + HMAC-SHA256 authenticated encryption), '
                          'protected by a passphrase that only you set and know.\n\n'
                          '• The Developer never sees this passphrase and cannot recover it if you forget it. A forgotten passphrase means the backup is permanently unreadable by design.\n'
                          '• Storing exported backup files safely is solely your responsibility.\n'
                          '• Restoring a backup replaces local data with the backup contents.',
                        ),

                        // Section 4: Data Retention and Deletion
                        _buildSectionHeader('4. Data Retention and Deletion'),
                        _buildParagraph(
                          'Your data persists on your device until deleted in-app or until the App is uninstalled.\n\n'
                          '• To delete specific records: use the in-app delete functions.\n'
                          '• Secure Deletion: SQLite PRAGMA secure_delete is enabled, and deleted receipt files undergo physical zero-overwrite before unlinking.\n'
                          '• To delete all data: wipe local data in settings or uninstall the App.\n'
                          '• Automatic OS cloud backup is disabled (allowBackup=false).',
                        ),

                        // Section 5: Your Rights
                        _buildSectionHeader('5. Your Rights'),
                        _buildParagraph(
                          'Because the App collects no personal data on any server, data-protection framework rights (access, correction, deletion, portability) '
                          'are satisfied inherently by the App\'s local-only design — you have full, direct, and exclusive control over your data at all times.',
                        ),

                        // Section 6: Children's Privacy
                        _buildSectionHeader('6. Children\'s Privacy'),
                        _buildParagraph(
                          'WalletMelt is intended for individuals managing personal finances (adults or older teenagers) and collects no data from anyone of any age on any server.',
                        ),

                        // Section 7: Future Versions Roadmap
                        _buildSectionHeader('7. Future Versions — Roadmap Disclosure'),
                        _buildParagraph(
                          '• V2: On-device receipt OCR processing (remaining local-only with no data transmission).\n'
                          '• V3: Optional cloud infrastructure for backup/sync.\n\n'
                          'If cloud features are introduced in future versions, this Privacy Policy will be substantially updated, and explicit consent will be required prior to any data transmission.',
                        ),

                        // Section 8: Risks and Limitations
                        _buildSectionHeader('8. Risks and Limitations You Should Understand'),
                        _buildParagraph(
                          '1. No off-device backup exists unless you make one. If your device is lost or damaged, unbacked data is permanently unrecoverable.\n'
                          '2. A forgotten backup passphrase makes that backup permanently unreadable.\n'
                          '3. Local security measures are best-effort; a compromised device (e.g. rooted or malware-infected) may expose local files.\n'
                          '4. Informational only: calculations and budget projections do not constitute professional financial advice.\n'
                          '5. Hobby project in passive development with no service-level agreement.',
                        ),

                        // Section 9: Disclaimer of Warranties
                        _buildSectionHeader('9. Disclaimer of Warranties'),
                        _buildParagraph(
                          'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, '
                          'INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, ACCURACY, RELIABILITY, OR NON-INFRINGEMENT.',
                        ),

                        // Section 10: Limitation of Liability
                        _buildSectionHeader('10. Limitation of Liability'),
                        _buildParagraph(
                          'TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE DEVELOPER SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, '
                          'INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF DATA, LOSS OF FUNDS, OR OTHER FINANCIAL LOSS '
                          'ARISING OUT OF YOUR USE OF THE APP.',
                        ),

                        // Section 11: Not Financial Advice
                        _buildSectionHeader('11. Not Financial, Tax, or Legal Advice'),
                        _buildParagraph(
                          'WalletMelt is a record-keeping and budgeting tool. Nothing it displays constitutes financial, investment, tax, or legal advice.',
                        ),

                        // Section 12: Governing Law
                        _buildSectionHeader('12. Governing Law'),
                        _buildParagraph(
                          'This Policy is governed by the laws of Pakistan, without regard to conflict-of-law principles, subject to mandatory local consumer protection regulations.',
                        ),

                        // Section 13: Changes to This Policy
                        _buildSectionHeader('13. Changes to This Policy'),
                        _buildParagraph(
                          'This Policy may be updated at major version milestones. The "Last Updated" date reflects the current revision.',
                        ),

                        // Section 14: Contact
                        _buildSectionHeader('14. Contact'),
                        _buildParagraph(
                          'Questions regarding this Policy or WalletMelt may be directed to:\n'
                          'Developer: Sheikh Muhammad Muneeb\n'
                          'Email: smmuneeb02@gmail.com',
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar (in Consent Mode)
                if (widget.isConsentMode) ...[
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? WalletMeltColors.darkSurface.withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.95),
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          type: MaterialType.transparency,
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: _hasAcceptedCheckbox,
                            onChanged: (val) {
                              setState(() {
                                _hasAcceptedCheckbox = val ?? false;
                              });
                            },
                            title: Text(
                              'I have read and agree to the Privacy Policy & Legal Disclaimer.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Action Buttons with generous breathing room
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: WalletMeltColors.brand,
                                foregroundColor: WalletMeltColors.textPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _hasAcceptedCheckbox
                                  ? _onAcceptAndContinue
                                  : null,
                              child: const Text(
                                'Accept & Continue',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(
                                  color: isDark ? Colors.white24 : Colors.black26,
                                ),
                              ),
                              onPressed: _onDeclineAndExit,
                              child: const Text(
                                'Decline & Exit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: isDark
              ? WalletMeltColors.darkTextSecondary
              : WalletMeltColors.textSecondary,
        ),
      ),
    );
  }
}
