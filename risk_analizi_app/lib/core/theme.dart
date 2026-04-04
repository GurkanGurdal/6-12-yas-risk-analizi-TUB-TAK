import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Palette
  static const Color primaryBlue = Color(0xFF6366F1);
  static const Color secondaryBlue = Color(0xFF8B5CF6);
  static const Color accentGold = Color(0xFF06B6D4);
  static const Color accentPeach = Color(0xFFF97316);

  // Backgrounds
  static const Color backgroundLight = Color(0xFF4338CA);
  static const Color backgroundOffWhite = Color(0xFFF1F5F9);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Text
  static const Color textDark = Color(0xFF0F172A);
  static const Color textGray = Color(0xFF64748B);
  static const Color textOnDark = Color(0xFFF8FAFC);
  static const Color mutedOnDark = Color(0xFFCBD5E1);

  // Risk Colors
  static const Color riskGreen = Color(0xFF10B981);
  static const Color riskYellow = Color(0xFFF59E0B);
  static const Color riskRed = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Neumorphism ──
  static const Color nBase = Color(0xFFE4E9F2);
  static const Color nDark = Color(0xFFA3B1C6);
  static const Color nLight = Color(0xFFFFFFFF);

  // ── flutter_neumorphic_plus Style Helpers ──

  static NeumorphicStyle nConvex({double radius = 22, double depth = 8}) =>
      NeumorphicStyle(
        shape: NeumorphicShape.convex,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(radius)),
        depth: depth,
        intensity: 0.65,
        surfaceIntensity: 0.15,
        color: nBase,
      );

  static NeumorphicStyle nFlat({double radius = 22, double depth = 8}) =>
      NeumorphicStyle(
        shape: NeumorphicShape.flat,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(radius)),
        depth: depth,
        intensity: 0.65,
        color: nBase,
      );

  static NeumorphicStyle nConcave({double radius = 22, double depth = -4}) =>
      NeumorphicStyle(
        shape: NeumorphicShape.concave,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(radius)),
        depth: depth,
        intensity: 0.65,
        surfaceIntensity: 0.15,
        color: nBase,
      );

  static NeumorphicStyle nCircle({double depth = 6}) => NeumorphicStyle(
        shape: NeumorphicShape.convex,
        boxShape: const NeumorphicBoxShape.circle(),
        depth: depth,
        intensity: 0.65,
        surfaceIntensity: 0.15,
        color: nBase,
      );

  static NeumorphicStyle nCircleConcave({double depth = -4}) =>
      NeumorphicStyle(
        shape: NeumorphicShape.concave,
        boxShape: const NeumorphicBoxShape.circle(),
        depth: depth,
        intensity: 0.65,
        surfaceIntensity: 0.15,
        color: nBase,
      );

  static NeumorphicThemeData get neumorphicTheme => const NeumorphicThemeData(
        baseColor: nBase,
        lightSource: LightSource.topLeft,
        depth: 8,
        intensity: 0.65,
      );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundOffWhite,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentGold,
        tertiary: secondaryBlue,
        surface: backgroundOffWhite,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          color: textDark,
          fontWeight: FontWeight.w700,
          fontSize: 32,
        ),
        titleLarge: GoogleFonts.poppins(
          color: textDark,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        bodyLarge: const TextStyle(color: textDark, fontSize: 16),
        bodyMedium: const TextStyle(color: textGray, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 68,
        foregroundColor: textDark,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark, size: 22),
        titleTextStyle: GoogleFonts.poppins(
          color: textDark,
          fontWeight: FontWeight.w700,
          fontSize: 21,
          letterSpacing: 0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: const Color(0xFFE2E8F0),
        thumbColor: primaryBlue,
        overlayColor: primaryBlue.withOpacity(0.12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEEF2FF),
        selectedColor: primaryBlue.withOpacity(0.15),
        secondarySelectedColor: primaryBlue.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE0E7FF)),
        ),
        labelStyle: const TextStyle(color: textDark, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.all(const BorderSide(color: Color(0xFFE0E7FF))),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? Colors.white : textDark,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? primaryBlue : Colors.white,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 1.8),
        ),
        labelStyle: const TextStyle(color: textGray, fontSize: 14),
      ),
    );
  }
}
