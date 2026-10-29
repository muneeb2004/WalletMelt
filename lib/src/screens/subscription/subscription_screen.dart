import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../components/category/category_icon.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/subscription.dart' as wm_sub;
import '../../types/subscription.dart' show SubscriptionStatus;
import '../../types/category.dart' as wm_cat;
import '../../utils/currency_format.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fluid_list.dart';
import 'subscription_form_sheet.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({this.isEmbedded = false, super.key});

  final bool isEmbedded;

  static void showAddSubscriptionSheet(BuildContext context) {
    showSubscriptionFormSheet(context);
  }

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionStatus _selectedFilter = SubscriptionStatus.active;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = state.settings.currency;
    final allSubs = state.subscriptions;

    final filteredSubs = allSubs.where((s) => s.status == _selectedFilter).toList();

    final content = Column(
      children: [
        if (!widget.isEmbedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Subscriptions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Add subscription',
                  onPressed: () => _showAddSubscriptionSheet(context),
                  icon: const Icon(Icons.add_rounded, size: 28),
                ),
              ],
            ),
          ),

        // Tabs / Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            children: [
              _FilterChip(
                label: 'Active',
                selected: _selectedFilter == SubscriptionStatus.active,
                color: context.money.incomeText,
                onTap: () => setState(() => _selectedFilter = SubscriptionStatus.active),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Paused',
                selected: _selectedFilter == SubscriptionStatus.paused,
                color: context.scheme.primary,
                onTap: () => setState(() => _selectedFilter = SubscriptionStatus.paused),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Cancelled',
                selected: _selectedFilter == SubscriptionStatus.cancelled,
                color: context.scheme.error,
                onTap: () => setState(() => _selectedFilter = SubscriptionStatus.cancelled),
              ),
            ],
          ),
        ),

        // Subscription List Content
        Expanded(
          child: filteredSubs.isEmpty
              ? Center(
                  child: EmptyState(
                    icon: Icons.repeat_rounded,
                    title: _selectedFilter == SubscriptionStatus.active
                        ? 'No active subscriptions'
                        : _selectedFilter == SubscriptionStatus.paused
                            ? 'No paused subscriptions'
                            : 'No cancelled subscriptions',
                    subtitle: _selectedFilter == SubscriptionStatus.active
                        ? 'Add Netflix, rent or the gym and renewals are logged for you.'
                        : 'Paused and cancelled subscriptions appear here.',
                    actionLabel: _selectedFilter == SubscriptionStatus.active ? 'Add subscription' : null,
                    onActionPressed: _selectedFilter == SubscriptionStatus.active
                        ? () => _showAddSubscriptionSheet(context)
                        : null,
                  ),
                )
              : ListView.builder(
                  padding: FluidList.padding,
                  physics: FluidList.physics,
                  itemCount: filteredSubs.length,
                  itemBuilder: (context, index) {
                    final sub = filteredSubs[index];
                    final category = state.categoryById(sub.categoryId);
                    return FluidItem(
                      index: index,
                      child: Padding(
                      padding: const EdgeInsets.only(bottom: FluidList.gap),
                      child: _SubscriptionCard(
                        subscription: sub,
                        category: category,
                        currency: currency,
                        onTap: () => _showSubscriptionActions(context, sub),
                      ),
                    ));
                  },
                ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      body: AppBackground(
        child: content,
      ),
    );
  }

  void _showAddSubscriptionSheet(BuildContext context) {
    showSubscriptionFormSheet(context);
  }

  void _showSubscriptionActions(BuildContext context, wm_sub.Subscription sub) {
    showAppBottomSheet(
      context,
      builder: (context) => _SubscriptionActionsSheet(subscription: sub),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 44.0),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.18)
                : context.scheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.35)
                  : context.scheme.onSurface.withValues(alpha: 0.06),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? (color) : theme.textTheme.bodyMedium?.color,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.category,
    required this.currency,
    required this.onTap,
  });

  final wm_sub.Subscription subscription;
  final wm_cat.Category? category;
  final String currency;
  final VoidCallback onTap;

  String _formatRelativeRenewal(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(date.year, date.month, date.day)
        .difference(today)
        .inDays;
    if (diff == 0) return 'Renews today';
    if (diff == 1) return 'Renews tomorrow';
    if (diff > 1 && diff <= 7) return 'Renews in $diff days';
    if (diff < 0) return 'Renewal due';
    return 'Renews ${formatRenewalDate(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = context.scheme;

    final statusColor = switch (subscription.status) {
      SubscriptionStatus.active => context.money.incomeText,
      SubscriptionStatus.paused => scheme.primary,
      SubscriptionStatus.cancelled => scheme.error,
    };
    final statusLabel = switch (subscription.status) {
      SubscriptionStatus.active => 'Active',
      SubscriptionStatus.paused => 'Paused',
      SubscriptionStatus.cancelled => 'Cancelled',
    };
    final totalAmount = subscription.amount + (subscription.taxAmount ?? 0.0);
    final categoryColor =
        category != null ? colorFromHex(category!.color) : scheme.primary;

    return WMCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.smMd),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: CategoryIcon(
              icon: category?.icon,
              color: categoryColor,
              size: 22,
              defaultIcon: Icons.repeat_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.name,
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${subscriptionCycleLabel(subscription.billingCycle)} · ${_formatRelativeRenewal(subscription.nextOccurrenceDate)}',
                  style: textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subscription.taxAmount != null &&
                    subscription.taxAmount! > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${formatMoney(subscription.amount, currency)} + ${formatMoney(subscription.taxAmount!, currency)} tax',
                    style: textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.smMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatMoney(totalAmount, currency),
                  style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(statusLabel,
                  style: textTheme.labelSmall?.copyWith(color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionActionsSheet extends StatelessWidget {
  const _SubscriptionActionsSheet({required this.subscription});

  final wm_sub.Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    final scheme = context.scheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subscription.name, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Added ${subscription.createdAt.substring(0, 10)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          if (subscription.status != SubscriptionStatus.cancelled)
            _ActionButton(
              icon: Icons.edit_outlined,
              label: 'Edit subscription',
              color: scheme.primary,
              onTap: () {
                Navigator.pop(context);
                showSubscriptionFormSheet(context, existing: subscription);
              },
            ),
          if (subscription.status == SubscriptionStatus.active)
            _ActionButton(
              icon: Icons.pause_rounded,
              label: 'Pause',
              color: scheme.primary,
              onTap: () async {
                await state.updateSubscription(subscription.copyWith(
                  status: SubscriptionStatus.paused,
                  updatedAt: DateTime.now().toIso8601String(),
                ));
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            )
          else if (subscription.status == SubscriptionStatus.paused)
            _ActionButton(
              icon: Icons.play_arrow_rounded,
              label: 'Resume',
              color: context.money.incomeText,
              onTap: () async {
                await state.resumeSubscription(subscription);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          if (subscription.status != SubscriptionStatus.cancelled)
            _ActionButton(
              icon: Icons.cancel_outlined,
              label: 'Cancel subscription',
              color: scheme.error,
              onTap: () async {
                await state.updateSubscription(subscription.copyWith(
                  status: SubscriptionStatus.cancelled,
                  cancelledAt: DateTime.now().toIso8601String(),
                  updatedAt: DateTime.now().toIso8601String(),
                ));
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          Divider(height: AppSpacing.lg, color: scheme.outlineVariant),
          _ActionButton(
            icon: Icons.delete_forever_rounded,
            label: 'Delete subscription',
            color: scheme.error,
            isDestructive: true,
            onTap: () async {
              final confirm = await showConfirmDialog(
                context,
                title: 'Delete this subscription?',
                body:
                    'Expenses already recorded from it stay in your history.',
                confirmLabel: 'Delete',
                isDestructive: true,
              );

              if (confirm == true) {
                await state.deleteSubscription(subscription.id);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: WMCard(
        tone: WMCardTone.raised,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.smMd),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: isDestructive ? color : null),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.scheme.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }
}
