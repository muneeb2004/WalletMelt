import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';

OverlayEntry? _activeToastEntry;

void _showToast(BuildContext context, String message, bool isError) {
  // Trigger tactile haptic feedback using central service
  if (isError) {
    WMHaptics.error();
  } else {
    WMHaptics.success();
  }

  // Dismiss any existing toast immediately
  if (_activeToastEntry != null) {
    try {
      _activeToastEntry!.remove();
    } catch (_) {}
    _activeToastEntry = null;
  }

  final overlay = Overlay.of(context, rootOverlay: true);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      return AppToastWidget(
        message: message,
        isError: isError,
        onDismiss: () {
          if (entry.mounted) {
            entry.remove();
            if (_activeToastEntry == entry) {
              _activeToastEntry = null;
            }
          }
        },
      );
    },
  );

  _activeToastEntry = entry;
  overlay.insert(entry);
}

/// Shows a success toast notification overlay with [message].
void showSuccessSnackbar(BuildContext context, String message) {
  _showToast(context, message, false);
}

/// Shows an error toast notification overlay with [message].
void showErrorSnackbar(BuildContext context, String message) {
  _showToast(context, message, true);
}

class AppToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const AppToastWidget({
    required this.message,
    required this.isError,
    required this.onDismiss,
    super.key,
  });

  @override
  State<AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<AppToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  bool _isDismissing = false;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppMotion.slow,
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppMotion.bounce,
      reverseCurve: AppMotion.exit,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppMotion.exit,
    ));

    _controller.forward();

    // Auto-dismiss after 2.8 seconds using a cancellable Timer
    _dismissTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted && !_isDismissing) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (_isDismissing) return;
    setState(() {
      _isDismissing = true;
    });
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accentColor = widget.isError
        ? WalletMeltColors.danger
        : WalletMeltColors.positive;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragUpdate: (details) {
                // Swipe up to dismiss
                if (details.primaryDelta! < -4) {
                  _dismiss();
                }
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark 
                          ? WalletMeltColors.darkSurface.withValues(alpha: 0.90) 
                          : Colors.white.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.24),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.isError 
                                      ? Icons.error_outline_rounded 
                                      : Icons.check_circle_outline_rounded,
                                  color: accentColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.message,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.drag_handle_rounded,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3) ?? Colors.grey,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

