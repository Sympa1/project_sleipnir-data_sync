import 'package:flutter/material.dart';

/// Zentrale Farbpalette der App.
///
/// Alle Farben an einem Ort – so musst du nie wieder
/// denselben Hex-Code an 10 verschiedenen Stellen suchen.
abstract final class AppColors {
  /// Primärfarbe (Teal)
  static const primary = Color(0xFF19ABB3);

  /// Dunklerer Teal-Ton für Akzente
  static const primaryDark = Color(0xFF01696E);

  /// Hintergrund im hellen Modus
  static const surfaceLight = Color(0xFFEFF5F5);

  /// Hintergrund im dunklen Modus
  static const surfaceDark = Color(0xFF151C1D);
}
