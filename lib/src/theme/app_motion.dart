/// WalletMelt motion and animation constants (curves, durations).
///
/// Centralizes all animation configurations to ensure visual consistency
/// and ease of maintenance across screens and components.
library;

import 'package:flutter/widgets.dart';

abstract final class AppMotion {
  AppMotion._();

  // ── Micro-Interaction Scale ──────────────────────────────────────────────
  static const double buttonPressScale = 0.96;
  static const double cardPressScale = 0.98;

  // ── Animation Durations ──────────────────────────────────────────────────
  /// Quick responses like tap down transitions, chip state switches.
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard screen elements, fade ins, and active tab transitions.
  static const Duration medium = Duration(milliseconds: 250);

  /// Larger animations, page sheets sliding, progress bar fill.
  static const Duration slow = Duration(milliseconds: 350);

  /// Long animations like chart loading or major entry sequences.
  static const Duration verySlow = Duration(milliseconds: 500);

  // ── Animation Curves ─────────────────────────────────────────────────────
  /// Standard smooth entrance/exit curve.
  static const Curve standard = Curves.easeInOutCubic;

  /// Sleek decelerating curve for slide-ins or entries.
  static const Curve entrance = Curves.easeOutCubic;

  /// Fast acceleration for slide-outs or exits.
  static const Curve exit = Curves.easeInCubic;

  /// Bouncy back-elastic curve for premium visual feedback (e.g. keypads, FABs, toasts).
  static const Curve bounce = Curves.easeOutBack;

  /// Spring-like curve for natural tactile micro-interactions.
  static const Curve spring = Curves.elasticOut;
}
