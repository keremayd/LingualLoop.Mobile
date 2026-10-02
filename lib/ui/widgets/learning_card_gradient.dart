import 'package:flutter/material.dart';

/// Onaylı Karty yüzeyi; kartın en-boy oranından bağımsız 45° renk ekseni.
LinearGradient learningCardGradient(Size size) {
  final x = (size.width + size.height) / (2 * size.width);
  final y = (size.width + size.height) / (2 * size.height);
  return LinearGradient(
    colors: const [
      Color(0xFF68D73D),
      Color(0xFF56BEEA),
      Color(0xFFA647F0),
      Color(0xFFFDC041),
    ],
    stops: const [0.02, 0.38, 0.68, 1],
    begin: Alignment(-x, -y),
    end: Alignment(x, y),
  );
}
