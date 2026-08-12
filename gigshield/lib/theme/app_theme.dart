import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary brand colors (Coinbase System)
  static const primary = Color(0xFF0052FF);
  static const primaryLight = Color(0xFF578BFA);
  static const primaryDark = Color(0xFF003AB8);

  // Accent
  static const accent = Color(0xFF0052FF);
  static const accentLight = Color(0xFFE3F2FD);

  // Status colors
  static const success = Color(0xFF098551);
  static const warning = Color(0xFFE65100);
  static const danger = Color(0xFFCF2027);

  // Background
  static const bgDark = Color(0xFFFFFFFF); // Pure white body
  static const bgCard = Color(0xFFFFFFFF);      // Pure white cards
  static const bgCardLight = Color(0xFFEEF0F3); // Muted surface
  static const bgSurface = Color(0xFFF9FAFB); 

  // Text
  static const textPrimary = Color(0xFF0A0B0D); // Near black
  static const textSecondary = Color(0xFF5B616E); // Muted text
  static const textMuted = Color(0xFF8A919E); 

  // Borders
  static const borderLight = Color(0xFFEEF0F3);

  // Gradients (Flattened for Coinbase aesthetic)
  static const primaryGradient = LinearGradient(
    colors: [primary, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const successGradient = LinearGradient(
    colors: [success, success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const warningGradient = LinearGradient(
    colors: [warning, warning],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const dangerGradient = LinearGradient(
    colors: [danger, danger],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Onboarding Sub-theme ───────────────────────
  static const onboardBg = Color(0xFFFFFFFF);
  static const onboardCard = Color(0xFFFFFFFF);
  static const onboardBluePrimary = Color(0xFF0052FF);
  static const onboardBlueLight = Color(0xFF578BFA);
  static const onboardBlueSoft = Color(0xFFEEF0F3);
  static const onboardBluePale = Color(0xFFF9FAFB);
  static const onboardTextDark = Color(0xFF0A0B0D);
  static const onboardTextBody = Color(0xFF5B616E);
  static const onboardTextMuted = Color(0xFF8A919E);
  static const onboardBorder = Color(0xFFEEF0F3);
  static const onboardSuccess = Color(0xFF098551);
  static const onboardSuccessBg = Color(0xFFE8F5E9);
  static const onboardWarning = Color(0xFFE65100);
  static const onboardWarningBg = Color(0xFFFFF3E0);
  static const onboardDanger = Color(0xFFCF2027);
  static const onboardDangerBg = Color(0xFFFFEBEE);

  static const onboardGradient = LinearGradient(
    colors: [primary, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const onboardGradientSubtle = LinearGradient(
    colors: [bgCardLight, bgCardLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgDark,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.bgCard,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 8,
        shadowColor: AppColors.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          minimumSize: const Size(double.infinity, 56), // Rigid 56px Standard
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(56), // Pill standard
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(88, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(56),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
