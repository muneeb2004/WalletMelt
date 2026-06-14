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
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Image.asset(
                'assets/brand/optimized/walletmelt_main_logo_960.webp',
                height: 92,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                filterQuality: FilterQuality.high,
                semanticLabel: 'WalletMelt',
              ),
            ),
            const SizedBox(height: 28),
            Text('Know where your money went.',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: WalletMeltColors.brandDeep)),
            const SizedBox(height: 18),
            Text(
              'Track household expenses, attach bills and receipts, and see where the month’s money melted. Your v1 data stays on this device.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(labelText: 'Default currency'),
              items: [
                for (final currency in defaultCurrencyCodes)
                  DropdownMenuItem(value: currency, child: Text(currency)),
              ],
              onChanged: (value) =>
                  setState(() => _currency = value ?? _currency),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () =>
                  context.read<AppState>().completeOnboarding(_currency),
              child: const Text('Start tracking'),
            ),
          ],
        ),
      ),
    );
  }
}
