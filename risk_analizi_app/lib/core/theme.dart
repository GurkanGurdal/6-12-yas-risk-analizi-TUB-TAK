import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Renk Paleti (Premium Minimalist & Soft Medical)
  static const Color primaryBlue = Color(0xFF2B5876);
  static const Color secondaryBlue = Color(0xFF4E4376);
  static const Color backgroundLight = Color(0xFFF7F9FC);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGray = Color(0xFF64748B);
  
  // Risk Renkleri
  static const Color riskGreen = Color(0xFF10B981);
  static const Color riskYellow = Color(0xFFF59E0B);
  static const Color riskRed = Color(0xFFEF4444);

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: secondaryBlue,
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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
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
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: textGray, fontSize: 14),
      ),
    );
  }
}
