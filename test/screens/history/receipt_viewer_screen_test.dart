import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'package:wallet_melt/src/screens/history/receipt_viewer_screen.dart';
import 'package:wallet_melt/src/services/export/export_file_writer.dart';
import 'package:wallet_melt/src/services/export/export_share_service.dart';
import 'package:wallet_melt/src/state/app_state.dart';
import 'package:wallet_melt/src/types/category.dart' as wm;
import 'package:wallet_melt/src/types/expense.dart';
import 'package:wallet_melt/src/types/settings.dart';
import 'package:wallet_melt/src/types/grocery_item.dart';
import 'package:wallet_melt/src/types/budget.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_expense_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_category_repository.dart';
import 'package:wallet_melt/src/data/repositories/drift/drift_budget_repository.dart';
import 'package:wallet_melt/src/services/settings/settings_service.dart';

void main() {
  group('ReceiptViewerScreen widget tests', () {
    testWidgets('shows loading state initially', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File(p.join(tempDir.path, 'test_receipt.jpg'))..createSync();
      final receiptUri = tempFile.uri.toString();

      final appState = _appState()
        ..expenses = [_expense(id: 'has-receipt', title: 'Groceries', receiptUri: receiptUri)];

      await tester.pumpWidget(
        _viewerHarness(
          expenseId: 'has-receipt',
          appState: appState,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100)); // Clear pending Future.delayed timer
      tempDir.deleteSync(recursive: true);
    });

    testWidgets('displays error recovery screen if expense is not found', (tester) async {
      final appState = _appState();
      await tester.pumpWidget(
        _viewerHarness(
          expenseId: 'non-existent',
          appState: appState,
        ),
      );

      await tester.pump(); // Start checkFile
      await tester.pump(const Duration(milliseconds: 100)); // Finish async check

      expect(find.text('Failed to load receipt'), findsOneWidget);
      expect(find.textContaining('The receipt image file could not be found'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets('displays error recovery screen if receipt uri does not exist', (tester) async {
      final appState = _appState()
        ..expenses = [_expense(id: 'no-receipt', title: 'Coffee', receiptUri: null)];
      await tester.pumpWidget(
        _viewerHarness(
          expenseId: 'no-receipt',
          appState: appState,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Failed to load receipt'), findsOneWidget);
      expect(find.textContaining('The receipt image file could not be found'), findsOneWidget);
    });

    testWidgets('displays details sheet on button press', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File(p.join(tempDir.path, 'test_receipt.jpg'))..createSync();
      final receiptUri = tempFile.uri.toString();

      final appState = _appState()
        ..expenses = [_expense(id: 'has-receipt', title: 'Groceries', receiptUri: receiptUri)]
        ..categories = [_category(id: 'grocery', name: 'Food & Groceries')];

      await tester.pumpWidget(
        _viewerHarness(
          expenseId: 'has-receipt',
          appState: appState,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);

      await tester.tap(find.text('Details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Receipt Details'), findsOneWidget);
      expect(find.text('Food & Groceries'), findsOneWidget);
      expect(find.text('Rs 1,200'), findsNWidgets(2)); // formatted money

      tempDir.deleteSync(recursive: true);
    });

    testWidgets('triggers sharing action successfully', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File(p.join(tempDir.path, 'test_receipt.jpg'))..createSync();
      final receiptUri = tempFile.uri.toString();

      final appState = _appState()
        ..expenses = [_expense(id: 'has-receipt', title: 'Groceries', receiptUri: receiptUri)];
      final shareService = FakeExportShareService();

      await tester.pumpWidget(
        _viewerHarness(
          expenseId: 'has-receipt',
          appState: appState,
          shareService: shareService,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final shareButton = find.byTooltip('Share');
      expect(shareButton, findsOneWidget);

      await tester.tap(shareButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(shareService.shareCalled, isTrue);
      expect(shareService.lastFile?.path, tempFile.path);

      tempDir.deleteSync(recursive: true);
    });

    testWidgets('triggers export/save action successfully', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File(p.join(tempDir.path, 'test_receipt.jpg'))..createSync();
      final receiptUri = tempFile.uri.toString();

      final appState = _appState()
        ..expenses = [_expense(id: 'has-receipt', title: 'Groceries', receiptUri: receiptUri)];
      final exportService = FakeReceiptExportService()..mockSavePath = p.join(tempDir.path, 'saved.jpg');

      await tester.pumpWidget(
        _viewerHarness(
          expenseId: 'has-receipt',
          appState: appState,
          exportService: exportService,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final saveButton = find.byTooltip('Save to device');
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(exportService.saveCalled, isTrue);
      expect(exportService.lastUri, receiptUri);
      expect(exportService.lastFileName, 'receipt_Groceries.jpg');
      expect(find.textContaining('Receipt saved: saved.jpg'), findsOneWidget);

      tempDir.deleteSync(recursive: true);
    });

    testWidgets('double-tap toggles zoom and reset zoom option is visible', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File(p.join(tempDir.path, 'test_receipt.jpg'))..createSync();
      final receiptUri = tempFile.uri.toString();

      final appState = _appState()
        ..expenses = [_expense(id: 'has-receipt', title: 'Groceries', receiptUri: receiptUri)];

      await tester.pumpWidget(
        _viewerHarness(
          expenseId: 'has-receipt',
          appState: appState,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final imageFinder = find.byType(InteractiveViewer);
      expect(imageFinder, findsOneWidget);

      expect(find.byTooltip('Reset Zoom'), findsNothing);

      // Double tap to zoom
      await tester.tap(imageFinder);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(imageFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byTooltip('Reset Zoom'), findsOneWidget);

      await tester.tap(find.byTooltip('Reset Zoom'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byTooltip('Reset Zoom'), findsNothing);

      tempDir.deleteSync(recursive: true);
    });
  });
}

Widget _viewerHarness({
  required String expenseId,
  required AppState appState,
  ExportShareService? shareService,
  ReceiptExportService? exportService,
}) {
  final share = shareService ?? FakeExportShareService();
  final export = exportService ?? FakeReceiptExportService();
  return ChangeNotifierProvider.value(
    value: appState,
    child: MaterialApp(
      home: ReceiptViewerScreen(
        expenseId: expenseId,
        exportShareService: share,
        receiptExportService: export,
      ),
    ),
  );
}

AppState _appState() {
  final state = AppState.test(
    driftCategoryRepository: FakeDriftCategoryRepository(),
    driftExpenseRepository: FakeDriftExpenseRepository(),
    driftBudgetRepository: FakeDriftBudgetRepository(),
    settingsService: FakeSettingsService(),
  );
  state.settings = WalletMeltSettings.defaults.copyWith(
    hasCompletedOnboarding: true,
  );
  return state;
}

wm.Category _category({
  required String id,
  required String name,
}) {
  return wm.Category(
    id: id,
    name: name,
    icon: 'shopping_basket',
    color: '#000000',
    isDefault: true,
    createdAt: '2026-06-14T00:00:00.000',
    updatedAt: '2026-06-14T00:00:00.000',
  );
}

Expense _expense({
  required String id,
  required String title,
  String? receiptUri,
}) {
  return Expense(
    id: id,
    amount: 1200,
    currency: 'PKR',
    categoryId: 'grocery',
    title: title,
    date: '2026-06-14T00:00:00.000',
    isRecurring: false,
    createdAt: '2026-06-14T10:00:00.000',
    updatedAt: '2026-06-14T10:00:00.000',
    receiptImageUri: receiptUri,
  );
}

class FakeDriftCategoryRepository extends Fake implements DriftCategoryRepository {}

class FakeDriftExpenseRepository extends Fake implements DriftExpenseRepository {}

class FakeDriftBudgetRepository extends Fake implements DriftBudgetRepository {}

class FakeSettingsService extends SettingsService {
  WalletMeltSettings saved = WalletMeltSettings.defaults;
  @override
  Future<WalletMeltSettings> load() async => saved;
  @override
  Future<void> save(WalletMeltSettings settings) async {
    saved = settings;
  }
}

class FakeExportShareService implements ExportShareService {
  bool shareCalled = false;
  ExportFileResult? lastFile;

  @override
  Future<ExportShareResult> shareFile(
    ExportFileResult file, {
    Rect? sharePositionOrigin,
    String? subject,
    String? title,
  }) async {
    shareCalled = true;
    lastFile = file;
    return const ExportShareResult(
      status: ExportShareStatus.success,
      raw: 'success',
    );
  }
}

class FakeReceiptExportService implements ReceiptExportService {
  bool saveCalled = false;
  String? lastUri;
  String? lastFileName;
  String? mockSavePath;

  @override
  Future<String?> saveReceipt(String uri, String fileName) async {
    saveCalled = true;
    lastUri = uri;
    lastFileName = fileName;
    return mockSavePath;
  }
}
