import 'package:flutter/material.dart';
import '../../utils/haptics.dart';

/// Numeric keypad for digit entry, with a backspace button.
class NumberPad extends StatelessWidget {
  final ValueChanged<String> onKeyPress;
  final VoidCallback onDelete;

  const NumberPad({
    required this.onKeyPress,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildKey(String value) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                WMHaptics.light();
                onKeyPress(value);
              },
              borderRadius: BorderRadius.circular(40),
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.06),
              child: Container(
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget buildDeleteKey() {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                WMHaptics.selection();
                onDelete();
              },
              borderRadius: BorderRadius.circular(40),
              splashColor: theme.colorScheme.error.withValues(alpha: 0.12),
              highlightColor: theme.colorScheme.error.withValues(alpha: 0.06),
              child: Container(
                height: 72,
                alignment: Alignment.center,
                child: Icon(
                  Icons.backspace_outlined,
                  size: 26,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget buildEmptyKey() {
      return const Expanded(
        child: SizedBox(
          height: 72,
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            buildKey('1'),
            buildKey('2'),
            buildKey('3'),
          ],
        ),
        Row(
          children: [
            buildKey('4'),
            buildKey('5'),
            buildKey('6'),
          ],
        ),
        Row(
          children: [
            buildKey('7'),
            buildKey('8'),
            buildKey('9'),
          ],
        ),
        Row(
          children: [
            buildEmptyKey(),
            buildKey('0'),
            buildDeleteKey(),
          ],
        ),
      ],
    );
  }
}
