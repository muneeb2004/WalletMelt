import 'package:flutter/material.dart';
import '../theme/wallet_melt_theme.dart';

/// Shows the celebratory, friendly What's New modal sheet / dialog.
Future<void> showWhatsNewModal(BuildContext context, {VoidCallback? onDismissed}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF131722) : Colors.white,
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
                color: isDark ? Colors.white24 : Colors.black12,
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
                    color: WalletMeltColors.brand.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: WalletMeltColors.brand,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "What's New in v1.1.1",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        'Dynamic monthly budgets, category vector icons & smooth experience',
                        style: TextStyle(
                          fontSize: 12,
                          color: WalletMeltColors.textMuted,
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
              // Version 1.1.1 Highlights
              _buildSectionBadge(
                label: 'VERSION 1.1.1 UPDATES',
                color: WalletMeltColors.brand,
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(
                icon: Icons.savings_rounded,
                iconColor: const Color(0xFF00B894),
                title: 'Dynamic Monthly Budgets',
                description:
                    'Set dynamic budget ceilings for individual months with adaptive insights. Roll over your remaining budget ceiling from the previous month with a single tap.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(
                icon: Icons.category_rounded,
                iconColor: const Color(0xFF6C5CE7),
                title: 'Vector Icons & Presets',
                description:
                    'Crisp vector SVG icons for all default categories, 12 curated custom category presets, and safeguarded SVG file uploads.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFFDCB6E),
                title: 'Dashboard Polish',
                description:
                    'A personalized time-aware greeting and enhanced breathing room across the Total Spend and metric cards for a cleaner look.',
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Version 1.1 Highlights
              _buildSectionBadge(
                label: 'VERSION 1.1 UPDATES',
                color: const Color(0xFF4EA8DE),
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF4EA8DE),
                title: 'Focused History',
                description:
                    "Your spending history now starts focused on the current month, saving your thumb from endless scrolling! Want to look back at last year's festive shopping? Just tap 'Show All' anytime.",
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(
                icon: Icons.arrow_back_rounded,
                iconColor: const Color(0xFF55EFC4),
                title: 'Back Button Freedom',
                description:
                    "Ever checked an expense and felt trapped because the back button wouldn't let you leave? That glitch has been officially evicted. The back button and your phone's swipe gestures now work smoothly every time.",
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(
                icon: Icons.palette_rounded,
                iconColor: const Color(0xFFE85D75),
                title: 'Your Colors, Your Vibe',
                description:
                    'Give your custom categories any shade under the sun! Pick from our fresh color palettes, slide through the interactive rainbow wheel, or type your favorite Hex code directly.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(
                icon: Icons.pin_invoke_rounded,
                iconColor: const Color(0xFFF4B740),
                title: 'Forgiving Number Entry',
                description:
                    'Type fast without worrying about formatting. Enter amounts with commas (1,250.50), European decimals (1.250,50), extra spaces, or accidental currency symbols—we clean it up and handle the math automatically.',
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Sneak Peek at v1.2 Card (Teaser)
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
                            color: const Color(0xFF6C5CE7).withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb_rounded,
                            color: Color(0xFF6C5CE7),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'SNEAK PEEK • COMING IN V1.2',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: isDark ? const Color(0xFFA29BFE) : const Color(0xFF6C5CE7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "We hear you! Many of you asked to tie monthly budgets directly to your real-world bank balance and roll over leftover savings from month to month.\n\nBecause personal financial workflows vary so widely, we are designing a comprehensive, flexible balance & savings engine to handle every scenario without complexity. It's actively in the oven for the big v1.2 release!",
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Version 1.0 Foundation Summary
              _buildSectionBadge(
                label: 'VERSION 1.0 FOUNDATION',
                color: const Color(0xFF64748B),
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFF64748B),
                title: '100% Offline & Private',
                description:
                    'No servers, no tracking, and no clouds. Your financial transactions stay strictly encrypted on your phone.',
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              _buildChangelogItem(
                icon: Icons.lock_rounded,
                iconColor: const Color(0xFF64748B),
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
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }

  Widget _buildChangelogItem({
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
                  color: isDark ? Colors.white : WalletMeltColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
