import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ChronoRep design system — "Graphite + Electric Blue".
/// Ported from the original web app's CSS custom properties so the Flutter
/// rewrite keeps the same athletic, data-forward visual language.
class AppColors {
  // Backgrounds
  static const bgPrimary = Color(0xFF090A0C); // hsl(240 8% 4%)
  static const bgSecondary = Color(0xFF12131A); // hsl(228 11% 8%)
  static const bgCard = Color(0xFF191A21); // hsl(225 10% 11%)
  static const bgCardHover = Color(0xFF20222B); // hsl(225 10% 14%)
  static const bgElevated = Color(0xFF262932); // hsl(225 9% 16%)
  static const bgInput = Color(0xFF14151C); // hsl(228 12% 9%)

  // Borders
  static const borderSubtle = Color(0x2957606E);
  static const borderDefault = Color(0x42646E7E);
  static const borderAccent = Color(0x732388FA);

  // Accents
  static const accent = Color(0xFF2388FA); // electric blue — hsl(212 96% 56%)
  static const accentDim = Color(0xFF2467B0);
  static const accentSecondary = Color(0xFF31B8F6); // cyan — hsl(199 92% 58%)
  static const accentGlow = Color(0x292388FA);

  static const success = Color(0xFF2BBA7F); // hsl(152 62% 45%)
  static const warning = Color(0xFFF5A623); // hsl(38 92% 55%)
  static const danger = Color(0xFFE05656); // hsl(0 70% 58%)

  // Text
  static const textPrimary = Color(0xFFF2F3F5); // hsl(220 14% 96%)
  static const textSecondary = Color(0xFF8F94A0); // hsl(222 9% 60%)
  static const textTertiary = Color(0xFF5C606B); // hsl(223 9% 40%)

  // Signature gradient (accent -> cyan)
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
