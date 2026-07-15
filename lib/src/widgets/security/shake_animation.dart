import 'dart:math';
import 'package:flutter/material.dart';

/// Horizontally shakes its [child] widget when triggered.
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;

  const ShakeAnimation({
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 16.0,
    super.key,
  });

  @override
  State<ShakeAnimation> createState() => ShakeAnimationState();
}

class ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Triggers the shake animation sequence.
  void shake() {
    _controller.forward(from: 0.0);
  }

  double _getOffset(double progress) {
    const cycles = 4;
    return sin(progress * cycles * 2 * pi) * widget.offset * (1 - progress);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_getOffset(_controller.value), 0.0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
