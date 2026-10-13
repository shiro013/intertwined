import 'package:flutter/material.dart';

class AppColors {
  // Luxury Dark Palette (Obsidian & Gold)
  static const Color background = Color(0xFF1A1A1A); // Obsidian
  static const Color surface = Color(0xFF333333); // Onyx
  static const Color surfaceVariant = Color(0xFF3D3D3D);

  // Primary/Accent
  static const Color primary = Color(0xFFE6D5B8); // Champagne Gold
  static const Color accent = Color(0xFFC5A059); // Gold Leaf
  static const Color onPrimary = Color(0xFF1A1A1A); // Obsidian text on gold

  // Text
  static const Color textPrimary = Color(0xFFFAFAF9); // Ivory
  static const Color textSecondary = Color(0xFFCCCCCC); // Silver
  static const Color textDisabled = Color(0xFF616161);

  // Status
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF81C784);

  // High-Fidelity Light Palette (Paper & Deep Gold)
  static const Color lightBackground = Color(0xFFFAFAF9); // Paper
  static const Color lightSurface = Color(0xFFEBEBEB); // Linen
  static const Color lightPrimary = Color(0xFF8A6D3B); // Deep Gold
  static const Color lightTextPrimary = Color(0xFF333333); // Obsidian
  static const Color lightTextSecondary = Color(0xFF666666);

  static Color? get secondary => null; // Charcoal
}
