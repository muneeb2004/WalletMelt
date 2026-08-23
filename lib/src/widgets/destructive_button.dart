import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';

/// Full-width destructive action button with touch scale response.
class DestructiveButton extends StatefulWidget {
  const DestructiveButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  State<DestructiveButton> createState() => _DestructiveButtonState();
}

class _DestructiveButtonState extends State<DestructiveButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final isEnabled = !widget.isLoading && widget.onPressed != null;

    final Widget child = widget.isLoading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
          )
        : widget.icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.label,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ],
              )
            : Text(
                widget.label,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              );

    return AnimatedScale(
      scale: isEnabled ? _scale : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.entrance,
      child: SizedBox(
        width: double.infinity,
        child: Listener(
          onPointerDown: isEnabled ? (_) => setState(() => _scale = AppMotion.buttonPressScale) : null,
          onPointerUp: isEnabled ? (_) => setState(() => _scale = 1.0) : null,
          onPointerCancel: isEnabled ? (_) => setState(() => _scale = 1.0) : null,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: error,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
            ),
            onPressed: isEnabled
                ? () {
                    WMHaptics.heavy();
                    widget.onPressed!();
                  }
                : null,
            child: child,
          ),
        ),
      ),
    );
  }
}

