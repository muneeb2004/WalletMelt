import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/app/wallet_melt_app.dart';

void main() {
  testWidgets('WalletMelt app boots to loading state',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const WalletMeltBootstrap(),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
