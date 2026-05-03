import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bgTop = Color(0xFF0F1B2D);
  static const bgBottom = Color(0xFF1B3A57);
  static const petal = Color(0xFFFF7AB6);
  static const petalDeep = Color(0xFFE0418A);
  static const leaf = Color(0xFF6BE3A1);
  static const leafDeep = Color(0xFF1FB36A);
  static const sun = Color(0xFFFFD86E);
  static const sunDeep = Color(0xFFE5A82A);
  // Vibrant default tile (indigo/violet gradient stops).
  static const tileTop    = Color(0xFF6E61F6);
  static const tileBottom = Color(0xFF3A2EA0);
  static const tileEdge   = Color(0xFF1B1145);
  static const tileSelectedTop    = Color(0xFFFF93C8);
  static const tileSelectedBottom = Color(0xFFE0418A);
  static const tileBloomTop    = Color(0xFF8DEFB1);
  static const tileBloomBottom = Color(0xFF1FB36A);
  static const tileBloomEdge   = Color(0xFF0E5A35);
  static const tileHintTop    = Color(0xFFFFE08A);
  static const tileHintBottom = Color(0xFFE5A82A);
  // Legacy names kept for backwards compatibility.
  static const tile = tileTop;
  static const tileSelected = tileSelectedBottom;
  static const tileBloom = tileBloomBottom;
  static const ink = Color(0xFF231B36);
  static const inkSoft = Color(0xFFEAE4F4);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bgTop,
    textTheme: GoogleFonts.fredokaTextTheme(base.textTheme).apply(
      bodyColor: AppColors.inkSoft,
      displayColor: Colors.white,
    ),
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.petal,
      secondary: AppColors.leaf,
      surface: AppColors.bgBottom,
    ),
  );
}
