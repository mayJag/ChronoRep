import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ChronoRep design system — "Mono & Crimson".
/// A restrained, high-contrast monochrome base with a single bold crimson
/// accent — an athletic, professional identity (Nike Training / Strava energy)
/// rather than the neon-on-black look of the first pass.
class AppColors {
  // Backgrounds — neutral near-black, no blue tint
  static const bgPrimary = Color(0xFF0A0A0B);
  static const bgSecondary = Color(0xFF121214);
  static const bgCard = Color(0xFF161618);
  static const bgCardHover = Color(0xFF1D1D20);
  static const bgElevated = Color(0xFF242427);
  static const bgInput = Color(0xFF111113);

  // Borders — neutral greys
  static const borderSubtle = Color(0x1FFFFFFF); // ~12% white
  static const borderDefault = Color(0x33FFFFFF); // ~20% white
  static const borderAccent = Color(0x66E23744);

  // Accents — crimson primary, coral-red secondary
  static const accent = Color(0xFFE23744); // crimson
  static const accentDim = Color(0xFFA81F2A);
  static const accentSecondary = Color(0xFFFF5A66); // coral-red
  static const accentGlow = Color(0x24E23744);

  static const success = Color(0xFF3DBB6B); // measured green
  static const warning = Color(0xFFE0A83B); // muted amber
  static const danger = Color(0xFFE23744); // crimson doubles as danger

  // Text — neutral, high contrast
  static const textPrimary = Color(0xFFF4F4F5);
  static const textSecondary = Color(0xFF9A9AA1);
  static const textTertiary = Color(0xFF5C5C62);

  // Signature gradient (crimson -> coral)
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentSecondary],
  );
}

class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 22.0;
  static const full = 999.0;
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgPrimary,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        secondary: AppColors.accentSecondary,
        surface: AppColors.bgCard,
        error: AppColors.danger,
      ),
      splashColor: AppColors.accentGlow,
      highlightColor: Colors.transparent,
      dividerColor: AppColors.borderSubtle,
    );
  }
}
