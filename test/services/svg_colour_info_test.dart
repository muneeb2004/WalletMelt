import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_melt/src/services/svg/svg_colour_info.dart';

String _svg(String body) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">$body</svg>';

void main() {
  test('two fixed colours are multicolour', () {
    expect(
        SvgColourInfo.isMulticolour(_svg(
            '<path fill="#E53935" d="M0 0h5v5z"/><path fill="#1E88E5" d="M6 6h5v5z"/>')),
        isTrue);
    expect(
        SvgColourInfo.isMulticolour(_svg(
            '<path style="fill:red;stroke:blue" d="M0 0h5v5z"/>')),
        isTrue);
  });

  test('gradients and images are multicolour', () {
    expect(
        SvgColourInfo.isMulticolour(
            _svg('<linearGradient id="g"/><path fill="url(#g)" d="M0 0h5v5z"/>')),
        isTrue);
  });

  test('single-colour and themed icons are tinted as before', () {
    expect(SvgColourInfo.isMulticolour(_svg('<path d="M0 0h5v5z"/>')), isFalse);
    expect(
        SvgColourInfo.isMulticolour(_svg(
            '<path fill="none" stroke="currentColor" d="M0 0h5v5z"/>')),
        isFalse);
    expect(
        SvgColourInfo.isMulticolour(_svg(
            '<path fill="#000" d="M0 0h5v5z"/><path fill="#000000" d="M6 6h5v5z"/>')),
        isFalse);
  });
}
