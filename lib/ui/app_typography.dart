import 'package:flutter/material.dart';

/// Karakterli kısa başlıklar Baloo 2; arayüz ve öğrenilen kelimeler Rubik.
/// Özel ekranların tasarım ölçeği korunur; yeni standart metinler tema kullanır.
abstract final class AppTypography {
  static const family = 'Rubik';
  static const displayFamily = 'Baloo 2';

  // Başlık ailesi yalnız heading rolünde; kelime ve sayaçlar Rubik kalır.
  static const word = FontWeight.w800;
  static const heading = FontWeight.w800;
  static const action = FontWeight.w700;
  static const number = FontWeight.w800;
  static const label = FontWeight.w700;
  static const caption = FontWeight.w600;
  static const body = FontWeight.w600;

  // Mantıksal piksel. Özel oyun yüzeyleri kendi ekran ölçeğini kullanır.
  static const textTheme = TextTheme(
    displayLarge: TextStyle(
        fontFamily: family, fontSize: 48, fontWeight: word, height: 1.1),
    displayMedium: TextStyle(
        fontFamily: family, fontSize: 44, fontWeight: word, height: 1.1),
    displaySmall: TextStyle(
        fontFamily: displayFamily,
        fontSize: 36,
        fontWeight: heading,
        height: 1.15),
    headlineLarge: TextStyle(
        fontFamily: displayFamily,
        fontSize: 30,
        fontWeight: heading,
        height: 1.2),
    headlineMedium: TextStyle(
        fontFamily: displayFamily,
        fontSize: 26,
        fontWeight: heading,
        height: 1.2),
    headlineSmall: TextStyle(
        fontFamily: displayFamily,
        fontSize: 24,
        fontWeight: heading,
        height: 1.2),
    titleLarge: TextStyle(
        fontFamily: displayFamily,
        fontSize: 22,
        fontWeight: heading,
        height: 1.25),
    titleMedium: TextStyle(
        fontFamily: family, fontSize: 18, fontWeight: label, height: 1.3),
    titleSmall: TextStyle(
        fontFamily: family, fontSize: 16, fontWeight: label, height: 1.3),
    bodyLarge: TextStyle(
        fontFamily: family, fontSize: 18, fontWeight: body, height: 1.4),
    bodyMedium: TextStyle(
        fontFamily: family, fontSize: 16, fontWeight: body, height: 1.4),
    bodySmall: TextStyle(
        fontFamily: family, fontSize: 14, fontWeight: body, height: 1.4),
    labelLarge: TextStyle(
        fontFamily: family, fontSize: 17, fontWeight: action, height: 1.2),
    labelMedium: TextStyle(
        fontFamily: family, fontSize: 14, fontWeight: label, height: 1.25),
    labelSmall: TextStyle(
        fontFamily: family, fontSize: 12, fontWeight: caption, height: 1.3),
  );
}
