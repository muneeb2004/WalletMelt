import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';
import 'package:wallet_melt/src/types/insight_action.dart';
import 'package:wallet_melt/src/types/insight_card.dart';
import 'package:wallet_melt/src/types/insight_data.dart';
import 'package:wallet_melt/src/types/spending_summaries.dart';
import 'package:wallet_melt/src/widgets/insights/insight_card_shell.dart';
import 'package:wallet_melt/src/widgets/insights/insight_content.dart';
import 'package:wallet_melt/src/widgets/insights/spending_summary_section.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      theme: WalletMeltTheme.light(),
      darkTheme: WalletMeltTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );
  }

  group('Insight Widgets', () {
    testWidgets('InsightCardShell renders title, header pill, and triggers action callback', (tester) async {
      InsightAction? tappedAction;

      final card = InsightCard(
        id: 'test_card_1',
        type: InsightType.whySpendingChanged,
        taxonomy: InsightTaxonomy.behavioral,
        severity: InsightSeverity.warning,
        title: 'Spending Increased',
        description: 'Dining drove 62% of the increase.',
        priority: 0.85,
        data: const WhyChangedData(
          totalDelta: 5000,
          isIncrease: true,
          topContributorCategoryId: 'cat_dining',
          topContributorName: 'Dining',
          topContributorDelta: 3100,
          directionalContributionPercent: 62.0,
          currentTotal: 15000,
          previousTotal: 10000,
        ),
        action: const InsightAction.viewCategory(categoryId: 'cat_dining'),
      );

      await tester.pumpWidget(wrapWidget(
        InsightCardShell(
          card: card,
          content: const Text('Custom Content'),
          onAction: (action) => tappedAction = action,
        ),
      ));

      expect(find.text('WARNING · BEHAVIORAL'), findsOneWidget);
      expect(find.text('Spending Increased'), findsOneWidget);
      expect(find.text('Custom Content'), findsOneWidget);
      expect(find.text('View breakdown →'), findsOneWidget);

      await tester.tap(find.text('View breakdown →'));
      await tester.pump();

      expect(tappedAction, isNotNull);
      expect(tappedAction!.type, InsightActionType.viewCategory);
      expect(tappedAction!.targetId, 'cat_dining');
    });

    testWidgets('InsightContent renders WhyChangedContent correctly', (tester) async {
      const data = WhyChangedData(
        totalDelta: 5000,
        isIncrease: true,
        topContributorCategoryId: 'cat_dining',
        topContributorName: 'Dining',
        topContributorDelta: 3100,
        directionalContributionPercent: 62.0,
        currentTotal: 15000,
        previousTotal: 10000,
      );

      await tester.pumpWidget(wrapWidget(
        const InsightContent(
          data: data,
          currency: 'PKR',
        ),
      ));

      expect(find.text('Top Driver'), findsOneWidget);
      expect(find.text('Dining'), findsOneWidget);
      expect(find.text('62% contribution'), findsOneWidget);
    });

    testWidgets('SpendingSummarySection renders categories, merchants, and largest transactions', (tester) async {
      String? tappedCategory;
      String? tappedTransaction;

      const summaries = SpendingSummaries(
        topCategories: [
          CategorySummaryItem(
            categoryId: 'cat_dining',
            categoryName: 'Dining',
            netAmount: 5000,
            percentOfTotal: 50,
            positiveTransactionCount: 4,
            refundCount: 0,
          ),
        ],
        topMerchants: [
          MerchantSummaryItem(
            merchantKey: 'vendor:subway',
            displayName: 'Subway',
            netAmount: 3000,
            positiveTransactionCount: 3,
            refundCount: 0,
            percentOfTotal: 30,
          ),
        ],
        largestExpenses: [
          TransactionSummaryItem(
            id: 'exp_1',
            title: 'Dinner with friends',
            amount: 2500,
            date: '2026-08-10',
            categoryId: 'cat_dining',
            categoryName: 'Dining',
            vendor: 'Subway',
          ),
        ],
      );

      await tester.pumpWidget(wrapWidget(
        SpendingSummarySection(
          summaries: summaries,
          currency: 'PKR',
          onCategoryTap: (cat) => tappedCategory = cat,
          onTransactionTap: (id) => tappedTransaction = id,
        ),
      ));

      expect(find.text('Spending Summaries'), findsOneWidget);
      expect(find.text('Top Categories'), findsOneWidget);
      expect(find.text('Top Merchants'), findsOneWidget);
      expect(find.text('Largest Transactions'), findsOneWidget);
      expect(find.text('Dinner with friends'), findsOneWidget);

      await tester.tap(find.text('Dining').first);
      await tester.pump();
      expect(tappedCategory, 'cat_dining');

      await tester.tap(find.text('Dinner with friends'));
      await tester.pump();
      expect(tappedTransaction, 'exp_1');
    });
  });
}
