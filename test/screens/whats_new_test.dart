import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/constants/app_version.dart';
import 'package:wallet_melt/src/widgets/whats_new_dialog.dart';

void main() {
  group("What's New Widget & Content Tests", () {
    testWidgets('renders release notes for every version and the next-release teaser', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WhatsNewContent(isEmbedded: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for the current version section badge & items
      expect(find.text('VERSION ${AppVersion.version} UPDATES'), findsOneWidget);
      expect(find.text('Savings goals'), findsOneWidget);
      expect(find.text('Your balance stays true'), findsOneWidget);
      expect(find.text('How much each month'), findsOneWidget);
      expect(find.text('Mark it achieved'), findsOneWidget);

      // Check for v1.5.1 section badge & items
      expect(find.text('VERSION 1.5.1 UPDATES'), findsOneWidget);
      expect(find.text('Link subscriptions you already have'), findsOneWidget);
      expect(find.text('Link loans and debts you already have'), findsOneWidget);

      // Check for v1.5.0 section badge & items
      expect(find.text('VERSION 1.5.0 UPDATES'), findsOneWidget);
      expect(find.text('Subscriptions pay from an account'), findsOneWidget);
      expect(find.text('Loans and debts update your balance'), findsOneWidget);
      expect(find.text('Backups include the links'), findsOneWidget);

      // Check for v1.4.0 section badge & items
      expect(find.text('VERSION 1.4.0 UPDATES'), findsOneWidget);
      expect(find.text('Budget from payday'), findsOneWidget);
      expect(find.text('Your history comes along'), findsOneWidget);
      expect(find.text('Balance and income in the tour'), findsOneWidget);

      // Check for v1.3.0 section badge & items
      expect(find.text('VERSION 1.3.0 UPDATES'), findsOneWidget);
      expect(find.text('Know what you have'), findsOneWidget);
      expect(find.text('Record your income'), findsOneWidget);
      expect(find.text('Move money between accounts'), findsOneWidget);
      expect(find.text('A budget idea from your income'), findsOneWidget);
      expect(find.text('Say where you paid from'), findsOneWidget);
      expect(find.text('Still private and offline'), findsOneWidget);

      // Check for v1.2.1 section badge & items
      expect(find.text('VERSION 1.2.1 UPDATES'), findsOneWidget);
      expect(find.text('Edit any icon'), findsOneWidget);
      expect(find.text('Save as a new icon'), findsOneWidget);
      expect(find.text('29 more default icons'), findsOneWidget);
      expect(find.text('Edits show everywhere'), findsOneWidget);

      // Check for v1.2.0 section badge & items
      expect(find.text('VERSION 1.2.0 UPDATES'), findsOneWidget);
      expect(find.text('A fresh, consistent look'), findsOneWidget);
      expect(find.text('Simpler navigation'), findsOneWidget);
      expect(find.text('Easier to read'), findsOneWidget);
      expect(find.text('Safer backups'), findsOneWidget);
      expect(find.text('More reliable renewals'), findsOneWidget);

      // Check for v1.1.2 section badge & items
      expect(find.text('VERSION 1.1.2 UPDATES'), findsOneWidget);
      expect(find.text('Across-the-Board SVG Customization'), findsOneWidget);
      expect(find.text('Financial Metrics Transparency'), findsOneWidget);
      expect(find.text('Settings & Visual Overhaul'), findsOneWidget);

      // Check for v1.1.1 section badge & items
      expect(find.text('VERSION 1.1.1 UPDATES'), findsOneWidget);
      expect(find.text('Dynamic Monthly Budgets'), findsOneWidget);
      expect(find.text('Vector Icons & Presets'), findsOneWidget);
      expect(find.text('Dashboard Polish'), findsOneWidget);

      // Check for v1.1 section badge & items
      expect(find.text('VERSION 1.1 UPDATES'), findsOneWidget);
      expect(find.text('Focused History'), findsOneWidget);
      expect(find.text('Back Button Freedom'), findsOneWidget);
      expect(find.text('Your Colors, Your Vibe'), findsOneWidget);
      expect(find.text('Forgiving Number Entry'), findsOneWidget);

      // Check for v1.2 teaser
      expect(find.text('SNEAK PEEK • COMING NEXT'), findsOneWidget);
      expect(find.textContaining('manage their budget according to their bank balance', findRichText: true), findsNothing);
      expect(find.textContaining('committees (BC)', findRichText: true), findsOneWidget);
    });

    testWidgets('showWhatsNewModal opens bottom sheet with close button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showWhatsNewModal(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text("What's New in ${AppVersion.displayVersion}"), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);

      // Tap close button in header
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.text("What's New in ${AppVersion.displayVersion}"), findsNothing);
    });
  });
}
