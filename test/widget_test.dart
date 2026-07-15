import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wallet_melt/src/app/wallet_melt_app.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/security/pin_lock_controller.dart';

void main() {
  testWidgets('WalletMelt app boots to loading state',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider<PinLockController>(create: (_) => FakePinLockController()),
        ],
        child: const WalletMeltApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

class FakePinLockController extends PinLockController {
  FakePinLockController() : super();

  @override
  bool get isLocked => false;

  @override
  bool get isPinEnabled => false;

  @override
  bool get isInitialized => true;

  @override
  bool get isPinScreenOpen => false;

  @override
  set isPinScreenOpen(bool value) {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refreshPinStatus() async {}

  @override
  void unlock() {}

  @override
  void lock() {}

  @override
  Future<void> enablePin(String rawPin) async {}

  @override
  Future<void> disablePin() async {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}
}
