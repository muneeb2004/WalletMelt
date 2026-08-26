import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../constants/currencies.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  String _currency = 'PKR';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const AssetImage('assets/brand/optimized/walletmelt_main_logo_960.webp'),
      context,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppBackground(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          children: [
            // Elegant Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Image.asset(
                    'assets/brand/optimized/walletmelt_main_logo_960.webp',
                    height: 32,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    semanticLabel: 'WalletMelt logo',
                  ),
                ),
                if (_currentPage < 2)
                  TextButton(
                    onPressed: _skipOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? WalletMeltColors.darkTextSecondary
                          : WalletMeltColors.textSecondary,
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  const SizedBox(height: 48), // Spacer to maintain alignment
              ],
            ),
            const SizedBox(height: 16),

            // Onboarding pages sliding area
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPageOne(context),
                  _buildPageTwo(context),
                  _buildPageThree(context),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Page dot indicators
            PageIndicator(count: 3, currentIndex: _currentPage),
            const SizedBox(height: 24),

            // Next / Start Tracking Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: WalletMeltColors.brand,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: WalletMeltColors.brand,
                  foregroundColor: WalletMeltColors.textPrimary,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: _currentPage < 2
                    ? _nextPage
                    : () =>
                        context.read<AppState>().completeOnboarding(_currency),
                child: Text(
                  _currentPage < 2 ? 'Next Feature' : 'Start Tracking',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bottom privacy assurance line
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: WalletMeltColors.textMuted,
                ),
                SizedBox(width: 6),
                Text(
                  '100% Offline & Private Local Database',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: WalletMeltColors.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageOne(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            '100% Offline & Private',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: WalletMeltColors.brandDeep,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your financial data stays completely on this device.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'WalletMelt uses a high-performance local SQLite database. We do not use cloud storage, request internet access, or collect analytics. No logins, no ads, no trackers.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 24),
          LiquidGlass(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      size: 28,
                      color: WalletMeltColors.positive,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Local-First Security',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSecurityFeatureRow(
                  context,
                  Icons.check_circle_outline_rounded,
                  'Zero Bytes Uploaded',
                  'No backend servers or cloud infrastructure exist to store your logs.',
                ),
                const SizedBox(height: 12),
                _buildSecurityFeatureRow(
                  context,
                  Icons.check_circle_outline_rounded,
                  'No Signup Required',
                  'Open the app and track immediately without sharing email or phone.',
                ),
                const SizedBox(height: 12),
                _buildSecurityFeatureRow(
                  context,
                  Icons.check_circle_outline_rounded,
                  'Full Database Control',
                  'Export your raw database or local backups to external files anytime.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeatureRow(
    BuildContext context,
    IconData icon,
    String title,
    String desc,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: WalletMeltColors.positive),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      height: 1.3,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageTwo(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Visual Budget Zones',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: WalletMeltColors.brandDeep,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Color-coded threshold alerts keep you in check.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Set strict monthly spending limits on your electricity, grocery, and gas categories. Progress bars shift automatically from green to orange and red, alerting you before you overspend.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 24),
          LiquidGlass(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.signal_cellular_alt_rounded,
                      size: 24,
                      color: WalletMeltColors.brand,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Live Budget Progression',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSimulatedBudgetBar(
                  category: 'Rent & Housing',
                  ratio: 0.35,
                  amountText: '350 / 1,000',
                  icon: Icons.home_rounded,
                  color: WalletMeltColors.positive,
                ),
                const SizedBox(height: 16),
                _buildSimulatedBudgetBar(
                  category: 'Groceries & Foods',
                  ratio: 0.78,
                  amountText: '390 / 500',
                  icon: Icons.shopping_basket_rounded,
                  color: WalletMeltColors.brand,
                ),
                const SizedBox(height: 16),
                _buildSimulatedBudgetBar(
                  category: 'Electricity Utilities',
                  ratio: 1.05,
                  amountText: '210 / 200',
                  icon: Icons.bolt_rounded,
                  color: WalletMeltColors.danger,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedBudgetBar({
    required String category,
    required double ratio,
    required String amountText,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Text(
              amountText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageThree(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final receiptBg =
        isDark ? const Color(0xFF16161C) : const Color(0xFFFAF9F6);
    final receiptBorderColor =
        isDark ? const Color(0x28FFFFFF) : const Color(0x28000000);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Itemized Tracking',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: WalletMeltColors.brandDeep,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Break down grocery bills to individual items.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Stop tracking just bulk transactions. Break grocery bills down into quantities, units, and rates, and attach photo receipts to keep complete visual records of your receipts.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 20),

          // Interactive Setup Card: Receipt Mockup + Currency Picker
          LiquidGlass(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Receipts Mockup
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: receiptBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: receiptBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'WHOLE FOODS MARKET',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Store #10432 - Austin, TX',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
                            color: WalletMeltColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const DottedLine(color: WalletMeltColors.textMuted),
                      const SizedBox(height: 8),
                      _buildReceiptItem('Whole Wheat Bread', 'x1', '\$3.50'),
                      _buildReceiptItem(
                          'Organic Whole Milk', 'x2 gal', '\$7.00'),
                      _buildReceiptItem('Fresh Bananas', 'x2.4 lbs', '\$2.28'),
                      const SizedBox(height: 8),
                      const DottedLine(color: WalletMeltColors.textMuted),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '\$12.78',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Currency Dropdown Selector
                Text(
                  'Set Default Currency',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                AppSpacing.gapSm,
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  dropdownColor:
                      isDark ? WalletMeltColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  isExpanded: true,
                  items: [
                    if (!supportedCurrencies.any((c) => c.code == _currency) &&
                        _currency.isNotEmpty)
                      DropdownMenuItem(
                        value: _currency,
                        child: Text(
                          _currency,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    for (final currency in supportedCurrencies)
                      DropdownMenuItem(
                        value: currency.code,
                        child: Text(
                          currency.displayLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  selectedItemBuilder: (context) {
                    return [
                      if (!supportedCurrencies
                              .any((c) => c.code == _currency) &&
                          _currency.isNotEmpty)
                        Text(
                          _currency,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      for (final currency in supportedCurrencies)
                        Text(
                          currency.displayLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                    ];
                  },
                  onChanged: (value) =>
                      setState(() => _currency = value ?? _currency),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptItem(String name, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 4),
                Text(
                  qty,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11,
                    color: WalletMeltColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class DottedLine extends StatelessWidget {
  const DottedLine({super.key, this.color = Colors.grey});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
