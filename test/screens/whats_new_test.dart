import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/widgets/whats_new_dialog.dart';

void main() {
  group("What's New in v1.1 Widget & Content Tests", () {
    testWidgets('renders v1.1 non-technical items and v1.2 teaser correctly', (tester) async {
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

      // Check for v1.1 section badge & items
      expect(find.text('VERSION 1.1 UPDATES'), findsOneWidget);
      expect(find.text('Focused History'), findsOneWidget);
      expect(find.text('Back Button Freedom'), findsOneWidget);
      expect(find.text('Your Colors, Your Vibe'), findsOneWidget);
      expect(find.text('Forgiving Number Entry'), findsOneWidget);

      // Check for v1.2 teaser
      expect(find.text('SNEAK PEEK • COMING IN V1.2'), findsOneWidget);
      expect(find.textContaining('manage their budget according to their bank balance', findRichText: true), findsNothing);
      expect(find.textContaining('bank balance and roll over leftover savings', findRichText: true), findsOneWidget);
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

      expect(find.text("What's New in v1.1"), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);

      // Tap close button in header
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.text("What's New in v1.1"), findsNothing);
    });
  });
}
