import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ChronoRep design system — "Amber Graphite & Violet".
/// A warmer, calmer graphite base (was cool blue-gray) with a single violet
/// brand accent, a strict semantic color set (green/amber/red used for meaning
/// only), and a three-family type system: Sora for display, Instrument Sans
/// for body/UI, and JetBrains Mono for every numeric readout.
class AppColors {
  // Surfaces — warm graphite, no blue tint
  static const bgPrimary = Color(0xFF12110F); // hsl(36 9% 6.5%)
  static const bgSecondary = Color(0xFF1E1C1A); // hsl(35 7% 11%)  card
  static const bgCard = Color(0xFF1E1C1A); // card
  static const bgCardHover = Color(0xFF262421); // hsl(35 7% 14%)  card2
  static const bgElevated = Color(0xFF2E2C28); // hsl(34 7% 17%)
  static const bgInput = Color(0xFF1A1916); // hsl(34 9% 9.5%)

  // Borders — warm greys at low alpha
  static const borderSubtle = Color(0x1FAEA598); // hsl(36 12% 64% / .12)
  static const borderDefault = Color(0x38AEA598); // hsl(36 12% 64% / .22)
  static const borderAccent = Color(0x66966CF9); // violet @ ~40%

  // Brand accent — violet primary (was electric blue / crimson)
  static const accent = Color(0xFF9D76F9); // hsl(258 92% 72%)
  static const accentPrimary2 = Color(0xFFC0A5FD); // hsl(258 95% 82%) hover
  static const accentDim = Color(0xFF38285D); // hsl(258 40% 26%)
  static const accentGlow = Color(0x52966CF9); // hsl(258 92% 70% / .32)
  static const accentSecondary = Color(0xFF3CCEEC); // cyan — charts/data only

  // Semantic — meaning only, never decorative
  static const success = Color(0xFF33CC80); // hsl(150 60% 50%)
  static const warning = Color(0xFFFBBA37); // hsl(40 96% 60%)
  static const danger = Color(0xFFEE6758); // hsl(6 82% 64%)

  static const successGlow = Color(0x2933CC80); // /.16
  static const warningGlow = Color(0x29FBBA37);
  static const dangerGlow = Color(0x29EE6758);

  // Text — warm off-white ramp
  static const textPrimary = Color(0xFFF4F3F0); // hsl(40 16% 95%)
  static const textSecondary = Color(0xFFA19B91); // hsl(38 8% 60%)
  static const textTertiary = Color(0xFF6D675F); // hsl(36 7% 40%)

  // Signature gradient — violet -> magenta-violet
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFFAD5CF5)],
  );
}

class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 22.0;
  static const full = 999.0;
}

/// Motion tokens shared across the redesign.
class AppMotion {
  /// Standard decelerate ease for entrances and layout.
  static const standard = Cubic(0.16, 1, 0.3, 1);

  /// Overshoot spring for buttons, checks, sheets, and dialogs.
  static const spring = Cubic(0.34, 1.56, 0.64, 1);
}

/// Display + numeric type helpers. Body/UI text inherits Instrument Sans from
/// the global [ThemeData.textTheme]; these two are opt-in for the pieces the
/// system calls out specifically.
class AppFonts {
  /// Sora — display / headings (600–700).
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.sora(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  /// JetBrains Mono — every numeric readout (weights, reps, timers, XP), with
  /// tabular figures so digits don't jitter as they change.
  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    // Body / UI: Instrument Sans.
    final body = GoogleFonts.instrumentSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    // Display / headline / title: Sora.
    TextStyle sora(TextStyle? s, FontWeight w) =>
        GoogleFonts.sora(textStyle: s, fontWeight: w);
    final textTheme = body.copyWith(
      displayLarge: sora(body.displayLarge, FontWeight.w700),
      displayMedium: sora(body.displayMedium, FontWeight.w700),
      displaySmall: sora(body.displaySmall, FontWeight.w700),
      headlineLarge: sora(body.headlineLarge, FontWeight.w700),
      headlineMedium: sora(body.headlineMedium, FontWeight.w600),
      headlineSmall: sora(body.headlineSmall, FontWeight.w600),
      titleLarge: sora(body.titleLarge, FontWeight.w600),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgPrimary,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.accentSecondary,
        surface: AppColors.bgCard,
        error: AppColors.danger,
      ),
      splashColor: AppColors.accentGlow,
      highlightColor: Colors.transparent,
      dividerColor: AppColors.borderSubtle,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: AppColors.accentDim,
        selectionHandleColor: AppColors.accent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
    );
  }
}
