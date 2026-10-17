import 'package:flutter/material.dart';
import '../constants/app_version.dart';
import '../theme/wallet_melt_theme.dart';

/// Shows the celebratory, friendly What's New modal sheet / dialog.
Future<void> showWhatsNewModal(BuildContext context, {VoidCallback? onDismissed}) async {

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.scheme.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.94,
        expand: false,
        builder: (sheetContext, scrollController) {
          return WhatsNewContent(
            scrollController: scrollController,
            onClose: () => Navigator.of(ctx).pop(),
          );
        },
      );
    },
  );

  onDismissed?.call();
}

/// The reusable content for the What's New changelog, used both in the
/// first-run modal and inside the persistent Settings section.
class WhatsNewContent extends StatelessWidget {
  const WhatsNewContent({
    super.key,
    this.scrollController,
    this.onClose,
    this.isEmbedded = false,
  });

  final ScrollController? scrollController;
  final VoidCallback? onClose;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        if (!isEmbedded) ...[
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.scheme.primary.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: context.scheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "What's New in ${AppVersion.displayVersion}",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        'Your balance, your income, all in one place',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],

        Padding(
          padding: EdgeInsets.symmetric(horizontal: isEmbedded ? 0 : 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Version 1.3.0 Highlights
              _buildSectionBadge(
                label: 'VERSION ${AppVersion.version} UPDATES',
                color: context.scheme.primary,
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.account_balance_wallet_rounded,
                iconColor: context.scheme.primary,
                title: 'Know what you have',
                description:
                    'Add your cash, bank and wallet accounts with what each one holds today. WalletMelt shows your total balance on Home and keeps it up to date as you log expenses.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.south_west_rounded,
                iconColor: context.money.income,
                title: 'Record your income',
                description:
                    'Add your salary, allowance or stipend and choose where it was paid. For money that repeats, WalletMelt asks you to confirm when it arrives, so your balance never changes by surprise.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.swap_horiz_rounded,
                iconColor: context.scheme.secondary,
                title: 'Move money between accounts',
                description:
                    'Withdraw cash or top up a wallet without it counting as spending. If your real balance is different, type it in and WalletMelt records the difference.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.lightbulb_rounded,
                iconColor: context.money.caution,
                title: 'A budget idea from your income',
                description:
                    'When you set your monthly budget, WalletMelt can suggest an amount based on the income you expect minus your subscriptions and regular bills. It is only a suggestion; your own budget always wins.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.credit_card_rounded,
                iconColor: context.scheme.primary,
                title: 'Say where you paid from',
                description:
                    'Pick an account when you add an expense. It is optional, and you can link older expenses to an account in one tap.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.lock_rounded,
                iconColor: context.scheme.secondary,
                title: 'Still private and offline',
                description:
                    'Everything stays on your phone. Your older backups still restore, and new backups include your accounts and income.',
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Version 1.2.1 Highlights
              _buildSectionBadge(
                label: 'VERSION 1.2.1 UPDATES',
                color: context.scheme.primary,
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.tune_rounded,
                iconColor: context.scheme.primary,
                title: 'Edit any icon',
                description:
                    'Open any built-in or custom icon and change its colour, line weight, outline or filled style, rotation, flip and size. Undo and redo as you go.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.copy_rounded,
                iconColor: context.money.income,
                title: 'Save as a new icon',
                description:
                    'Keep the original untouched: save your modified version as a separate custom icon and use it on any category.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.grid_view_rounded,
                iconColor: context.money.caution,
                title: '29 more default icons',
                description:
                    'Coffee, mobile, books, clothing, medicine, insurance, bus, flights, movies, bank, wallet and more: 41 ready-made icons in total.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.check_circle_rounded,
                iconColor: context.scheme.secondary,
                title: 'Edits show everywhere',
                description:
                    'Changing a built-in icon now updates the matching default category too, such as Electricity and Internet.',
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Version 1.2.0 Highlights
              _buildSectionBadge(
                label: 'VERSION 1.2.0 UPDATES',
                color: context.scheme.primary,
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.palette_rounded,
                iconColor: context.scheme.primary,
                title: 'A fresh, consistent look',
                description:
                    'Every screen now shares one design: a calm indigo brand, soft tonal surfaces, clearer text sizes and a true-black dark mode.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.space_dashboard_rounded,
                iconColor: context.scheme.secondary,
                title: 'Simpler navigation',
                description:
                    'A standard bottom bar with Home, History, Planning and Debts, and a single Add button wherever you add things.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.visibility_rounded,
                iconColor: context.money.income,
                title: 'Easier to read',
                description:
                    'Higher-contrast text, no more tiny labels, and budget colours that stay clear in both light and dark mode.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.verified_user_rounded,
                iconColor: context.money.caution,
                title: 'Safer backups',
                description:
                    'Backups now include everything, from debts and subscriptions to receipts, and are checksummed. Full Replace restores are verified before they are applied.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context,
                icon: Icons.autorenew_rounded,
                iconColor: context.scheme.primary,
                title: 'More reliable renewals',
                description:
                    'Subscription renewals are applied all or nothing, so a failure never leaves half-created expenses behind.',
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Version 1.1.2 Highlights
              _buildSectionBadge(
                label: 'VERSION 1.1.2 UPDATES',
                color: context.scheme.primary,
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context, 
                icon: Icons.draw_rounded,
                iconColor: context.scheme.primary,
                title: 'Across-the-Board SVG Customization',
                description:
                    'Full visual freedom! Customize any default or custom category with crisp vector SVGs, preset bundles, color tints, and interactive code editing.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context, 
                icon: Icons.calculate_rounded,
                iconColor: context.money.income,
                title: 'Financial Metrics Transparency',
                description:
                    'Demystify your finances. Dive into the new Metric Calculations screen to see deterministic mathematical formulas, live examples, and auditing for all insights.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context, 
                icon: Icons.tune_rounded,
                iconColor: context.money.caution,
                title: 'Settings & Visual Overhaul',
                description:
                    'Cleaner organization with dedicated Visual Customization and Financial Calculations menus, expanded layout breathing room, and instant live overrides.',
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Version 1.1.1 Highlights
              _buildSectionBadge(
                label: 'VERSION 1.1.1 UPDATES',
                color: context.money.income,
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context, 
                icon: Icons.savings_rounded,
                iconColor: context.money.income,
                title: 'Dynamic Monthly Budgets',
                description:
                    'Set dynamic budget ceilings for individual months with adaptive insights. Roll over your remaining budget ceiling from the previous month with a single tap.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context, 
                icon: Icons.category_rounded,
                iconColor: context.scheme.primary,
                title: 'Vector Icons & Presets',
                description:
                    'Crisp vector SVG icons for all default categories, 12 curated custom category presets, and safeguarded SVG file uploads.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context, 
                icon: Icons.wb_sunny_rounded,
                iconColor: context.money.caution,
                title: 'Dashboard Polish',
                description:
                    'A personalized time-aware greeting and enhanced breathing room across the Total Spend and metric cards for a cleaner look.',
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Version 1.1 Highlights
              _buildSectionBadge(
                label: 'VERSION 1.1 UPDATES',
                color: context.scheme.secondary,
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context, 
                icon: Icons.calendar_month_rounded,
                iconColor: context.scheme.secondary,
                title: 'Focused History',
                description:
                    "Your spending history now starts focused on the current month, saving your thumb from endless scrolling! Want to look back at last year's festive shopping? Just tap 'Show All' anytime.",
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context, 
                icon: Icons.arrow_back_rounded,
                iconColor: context.money.income,
                title: 'Back Button Freedom',
                description:
                    "Ever checked an expense and felt trapped because the back button wouldn't let you leave? That glitch has been officially evicted. The back button and your phone's swipe gestures now work smoothly every time.",
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context, 
                icon: Icons.palette_rounded,
                iconColor: context.scheme.error,
                title: 'Your Colors, Your Vibe',
                description:
                    'Give your custom categories any shade under the sun! Pick from our fresh color palettes, slide through the interactive rainbow wheel, or type your favorite Hex code directly.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context, 
                icon: Icons.pin_invoke_rounded,
                iconColor: context.money.caution,
                title: 'Forgiving Number Entry',
                description:
                    'Type fast without worrying about formatting. Enter amounts with commas (1,250.50), European decimals (1.250,50), extra spaces, or accidental currency symbols—we clean it up and handle the math automatically.',
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Sneak Peek at the next release (Teaser)
              WMGlassSurface.tier2(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: context.scheme.primary.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lightbulb_rounded,
                            color: context.scheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'SNEAK PEEK • COMING NEXT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: context.scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Next up: planning around payday or your semester, savings goals, and an optional way to add expenses from bank and wallet alerts on your phone. It will always be your choice and stay on your device.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Version 1.0 Foundation Summary
              _buildSectionBadge(
                label: 'VERSION 1.0 FOUNDATION',
                color: context.scheme.onSurfaceVariant,
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context, 
                icon: Icons.shield_rounded,
                iconColor: context.scheme.onSurfaceVariant,
                title: '100% Offline & Private',
                description:
                    'No servers, no tracking, and no clouds. Your financial transactions stay strictly encrypted on your phone.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(context, 
                icon: Icons.lock_rounded,
                iconColor: context.scheme.onSurfaceVariant,
                title: 'PIN Lock & Encrypted Backups',
                description:
                    'Military-grade PBKDF2 encryption protects your manual ZIP export archives, with fast PIN & biometric app locking.',
                isDark: isDark,
              ),

              if (!isEmbedded) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onClose,
                    child: const Text(
                      'Awesome, Let’s Go!',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ],
    );

    if (scrollController != null) {
      return ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [content],
      );
    }

    return content;
  }

  Widget _buildSectionBadge({
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }

  Widget _buildChangelogItem(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: context.scheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
