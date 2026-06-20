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
              child: Padding(
                padding: padding,
                child: child,
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
      // 1. Top-Right: Deep Indigo/Violet Glow
      final center1 = Offset(size.width * 0.85, size.height * 0.2);
      final radius1 = size.width * 0.6;
      paint.shader = RadialGradient(
        colors: [
          const Color(0xFF6366F1).withValues(alpha: 0.16),
          const Color(0xFF6366F1).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center1, radius: radius1));
      canvas.drawCircle(center1, radius1, paint);

      // 2. Bottom-Left: Amber Glow
      final center2 = Offset(size.width * 0.1, size.height * 0.75);
      final radius2 = size.width * 0.65;
      paint.shader = RadialGradient(
        colors: [
          const Color(0xFFF59E0B).withValues(alpha: 0.10),
          const Color(0xFFF59E0B).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center2, radius: radius2));
      canvas.drawCircle(center2, radius2, paint);

      // 3. Center-Right: Emerald Glow
      final center3 = Offset(size.width * 0.9, size.height * 0.55);
      final radius3 = size.width * 0.45;
      paint.shader = RadialGradient(
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.08),
          const Color(0xFF10B981).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center3, radius: radius3));
      canvas.drawCircle(center3, radius3, paint);
    } else {
      // 1. Top-Right: Pastel Gold Glow
      final center1 = Offset(size.width * 0.8, size.height * 0.15);
      final radius1 = size.width * 0.65;
      paint.shader = RadialGradient(
        colors: [
          const Color(0xFFFCD34D).withValues(alpha: 0.26),
          const Color(0xFFFCD34D).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center1, radius: radius1));
      canvas.drawCircle(center1, radius1, paint);

      // 2. Bottom-Left: Soft Mint/Emerald Glow
      final center2 = Offset(size.width * 0.15, size.height * 0.75);
      final radius2 = size.width * 0.7;
      paint.shader = RadialGradient(
        colors: [
          const Color(0xFFA7F3D0).withValues(alpha: 0.22),
          const Color(0xFFA7F3D0).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center2, radius: radius2));
      canvas.drawCircle(center2, radius2, paint);

      // 3. Center-Right: Light Sky Blue Glow
      final center3 = Offset(size.width * 0.85, size.height * 0.5);
      final radius3 = size.width * 0.5;
      paint.shader = RadialGradient(
        colors: [
          const Color(0xFFBAE6FD).withValues(alpha: 0.16),
          const Color(0xFFBAE6FD).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center3, radius: radius3));
      canvas.drawCircle(center3, radius3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundOrbsPainter oldDelegate) => false;
}
