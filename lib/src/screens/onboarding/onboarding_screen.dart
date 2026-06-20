import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../constants/categories.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _currency = 'PKR';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            // Logo area
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Image.asset(
                  'assets/brand/optimized/walletmelt_main_logo_960.webp',
                  height: 84,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  semanticLabel: 'WalletMelt logo',
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Central glassmorphic card for currency and configuration
            LiquidGlass(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Know where your money went.',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: WalletMeltColors.brandDeep,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Track household expenses, attach bills and receipts, and see where the month’s money melted. Your data stays securely on this device.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Default Currency',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    dropdownColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E24)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    items: [
                      for (final currency in defaultCurrencyCodes)
                        DropdownMenuItem(
                          value: currency,
                          child: Text(currency, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _currency = value ?? _currency),
                  ),
                ],
              ),
            ),
            const Spacer(),
            
            // Start Tracking Button (Premium Brand Gradient + Shadow Glow)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFCD34D), // Golden highlight
                    Color(0xFFF59E0B), // Brand amber
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.36),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFFB87912).withValues(alpha: 0.16),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: Colors.transparent,
                  foregroundColor: WalletMeltColors.textPrimary,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () =>
                    context.read<AppState>().completeOnboarding(_currency),
                child: const Text(
                  'Start tracking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            
            // Security subtitle
            const SizedBox(height: 12),
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 12, color: WalletMeltColors.textMuted),
                  SizedBox(width: 4),
                  Text(
                    '100% Offline & Private',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: WalletMeltColors.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
