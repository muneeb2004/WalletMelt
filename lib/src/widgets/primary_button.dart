import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';

/// Full-width primary action button with tactile spring feedback.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
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
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
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
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
            ),

            onPressed: isEnabled
                ? () {
                    WMHaptics.medium();
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

