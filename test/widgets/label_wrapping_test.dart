import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';
import 'package:wallet_melt/src/widgets/wm_sheet.dart';

/// Labels on buttons, FABs and nav items must stay on one line.
int _wrappedLabels(WidgetTester tester) {
  var wrapped = 0;
  void visit(RenderObject o) {
    if (o is RenderParagraph && o.size.height > 0) {
      final oneLine = o.getMinIntrinsicHeight(double.infinity);
      final lines = (o.size.height / oneLine).round();
      if (lines > 1) {
        final text = o.text.toPlainText();
        final el = find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText() == text);
        final inLabel = find.ancestor(
          of: el,
          matching: find.byWidgetPredicate((w) =>
              w is ButtonStyleButton ||
              w is FloatingActionButton ||
              w is NavigationBar),
        );
        if (inLabel.evaluate().isNotEmpty) {
          wrapped++;
          // ignore: avoid_print
          print('WRAPPED ($lines lines): "$text"');
        }
      }
    }
    o.visitChildren(visit);
  }

  visit(tester.binding.renderViews.first);
  return wrapped;
}

const _confirms = <(String, String, String)>[
  ('Move to recycle bin?', 'You can restore it later from History.', 'Move to recycle bin'),
  ('Delete forever?', 'This removes the expense and its receipt file.', 'Delete forever'),
  ('Deactivate contact?', 'This contact has linked transactions.', 'Deactivate'),
  ('Delete Dining out icon?', 'This removes the icon from your phone.', 'Delete icon'),
  ('Archive merchant?', 'Archiving removes it from suggestions.', 'Archive'),
];

Future<void> _loadFont() async {
  final loader = FontLoader('PlusJakartaSans')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFont);
  for (final width in [320.0, 360.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('confirm sheets keep button labels on one line '
          '(w=$width, text x$scale)', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        var wrapped = 0;
        for (final c in _confirms) {
          await tester.pumpWidget(MaterialApp(
            theme: WalletMeltTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: WMSheet(
                  title: c.$1,
                  subtitle: c.$2,
                  icon: Icons.delete_outline_rounded,
                  destructive: true,
                  actions: [
                    WMSheetButton(
                        label: 'Cancel',
                        kind: WMSheetButtonKind.secondary,
                        onPressed: () {}),
                    WMSheetButton(
                        label: c.$3,
                        kind: WMSheetButtonKind.destructive,
                        onPressed: () {}),
                  ],
                ),
              ),
            ),
          ));
          wrapped += _wrappedLabels(tester);
        }
        expect(wrapped, 0);
      });
    }
  }

  testWidgets('extended FAB labels stay on one line at 320 wide x1.3',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var wrapped = 0;
    for (final l in ['Add expense', 'Add', 'Add account', 'Add income',
      'Add goal', 'Add committee', 'Add merchant', 'Add contact']) {
      await tester.pumpWidget(MaterialApp(
        theme: WalletMeltTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
          floatingActionButton: FloatingActionButton.extended(
              onPressed: () {}, icon: const Icon(Icons.add), label: Text(l)),
        ),
      ));
      wrapped += _wrappedLabels(tester);
    }
    expect(wrapped, 0);
  });
}
