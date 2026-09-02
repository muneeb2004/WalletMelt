import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/theme/wallet_melt_theme.dart';
import 'package:wallet_melt/src/widgets/color_picker_sheet.dart';

void main() {
  group('colorFromHex & hexFromColor Tests', () {
    test('parses 6-digit hex with and without #', () {
      expect(colorFromHex('#FF0000'), const Color(0xFFFF0000));
      expect(colorFromHex('00FF00'), const Color(0xFF00FF00));
    });

    test('parses 3-digit shorthand hex', () {
      expect(colorFromHex('#F00'), const Color(0xFFFF0000));
      expect(colorFromHex('0F0'), const Color(0xFF00FF00));
    });

    test('parses 8-digit ARGB hex', () {
      expect(colorFromHex('#80FF0000'), const Color(0x80FF0000));
    });

    test('handles whitespace and returns fallback on invalid', () {
      expect(colorFromHex('  #E85D75  '), const Color(0xFFE85D75));
      expect(colorFromHex('invalid', fallback: Colors.blue), Colors.blue);
    });

    test('converts color to hex string', () {
      expect(hexFromColor(const Color(0xFFE85D75)), '#E85D75');
      expect(hexFromColor(const Color(0xFFE85D75), includeHash: false), 'E85D75');
    });
  });

  group('WMColorPicker Widget Tests', () {
    testWidgets('renders presets and selects a preset', (tester) async {
      String selected = '#8FD6B5';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return WMColorPicker(
                    selectedColor: selected,
                    onColorChanged: (newColor) {
                      setState(() => selected = newColor);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom...'), findsOneWidget);

      // Tap Custom... to open sliders and hex input
      await tester.tap(find.text('Custom...'));
      await tester.pumpAndSettle();

      expect(find.text('Color Hex Code'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2));

      // Enter a custom hex code
      await tester.enterText(find.byType(TextField), '#123456');
      await tester.pumpAndSettle();

      expect(selected, '#123456');
    });
  });
}
