import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Renk Paleti (Mor + Sicak Vurgu)
  static const Color primaryBlue = Color(0xFF312C51);
  static const Color secondaryBlue = Color(0xFF48426D);
  static const Color accentGold = Color(0xFFF0C38E);
  static const Color accentPeach = Color(0xFFF1AA9B);
  static const Color backgroundLight = Color(0xFF312C51);
  static const Color cardColor = Color(0x33FFFFFF);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGray = Color(0xFF64748B);
  static const Color textOnDark = Color(0xFFF5F2FF);
  static const Color mutedOnDark = Color(0xFFCFC8EA);
  
  // Risk Renkleri
  static const Color riskGreen = Color(0xFF10B981);
  static const Color riskYellow = Color(0xFFF59E0B);
  static const Color riskRed = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentGold,
        surface: backgroundLight,
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
        bodyLarge: const TextStyle(
          color: textDark,
          fontSize: 16,
        ),
        bodyMedium: const TextStyle(
          color: textGray,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryBlue,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        scrolledUnderElevation: 0,
        shadowColor: secondaryBlue,
        toolbarHeight: 68,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 21,
          letterSpacing: 0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: primaryBlue,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
        shadowColor: Colors.black.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.28), width: 1),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentGold,
        inactiveTrackColor: Colors.white.withOpacity(0.25),
        thumbColor: accentGold,
        overlayColor: accentGold.withOpacity(0.15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withOpacity(0.16),
        selectedColor: accentGold.withOpacity(0.35),
        secondarySelectedColor: accentGold.withOpacity(0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withOpacity(0.28)),
        ),
        labelStyle: const TextStyle(color: textOnDark, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStateProperty.all(BorderSide(color: Colors.white.withOpacity(0.25))),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? primaryBlue : textOnDark,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? accentGold : secondaryBlue,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.28)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentGold, width: 1.8),
        ),
        labelStyle: const TextStyle(color: mutedOnDark, fontSize: 14),
      ),
    );
  }
}
