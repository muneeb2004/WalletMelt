import 'package:flutter/material.dart';

import '../../theme/wallet_melt_theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    required this.child,
    super.key,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    
    // Rich deep base gradients to avoid flat boring backgrounds
    final baseGradient = dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF06050A), // Extremely deep space indigo
              Color(0xFF0F0E16), // Dark charcoal space background
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              WalletMeltColors.backgroundGradientStart,
              WalletMeltColors.background,
              WalletMeltColors.backgroundGradientEnd,
            ],
          );

    return Container(
      decoration: BoxDecoration(gradient: baseGradient),
      child: Stack(
        children: [
          // Glowing liquid orbs in the background layer
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundOrbsPainter(isDark: dark),
            ),
          ),
          // Screen content layer
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: padding,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw glowing, diffused radial gradient spheres (orbs)
/// in the background, creating context for backdrop blurs to shine.
class BackgroundOrbsPainter extends CustomPainter {
  BackgroundOrbsPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    if (isDark) {
      // Single top-right soft indigo glow
      final center = Offset(size.width * 0.8, size.height * 0.25);
      final radius = size.width * 0.8;
      paint.shader = RadialGradient(
        colors: [
          const Color(0xFF6366F1).withValues(alpha: 0.12),
          const Color(0xFF6366F1).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    } else {
      // Single top-right soft gold glow
      final center = Offset(size.width * 0.8, size.height * 0.2);
      final radius = size.width * 0.8;
      paint.shader = RadialGradient(
        colors: [
          const Color(0xFFFCD34D).withValues(alpha: 0.18),
          const Color(0xFFFCD34D).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundOrbsPainter oldDelegate) => false;
}
