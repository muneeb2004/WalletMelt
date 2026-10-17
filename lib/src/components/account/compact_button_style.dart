import 'package:flutter/material.dart';

/// The app theme gives filled/outlined buttons `Size.fromHeight(52)` (full
/// width). Buttons placed in a [Row] or [Wrap] need a finite minimum width.
const ButtonStyle compactButtonStyle = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(0, 48)),
);
