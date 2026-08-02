import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Palette ─────────────────────────────────────────────────────────────
  static const Color bg        = Color(0xFFF5F5DC); // warm off-white base
  static const Color pale      = Color(0xFFECECA3); // #ececa3 – lightest lime
  static const Color limeLight = Color(0xFFB5E550); // #b5e550 – bright lime
  static const Color primary   = Color(0xFFABC32F); // #abc32f – primary olive
  static const Color secondary = Color(0xFF809C13); // #809c13 – mid olive
  static const Color dark      = Color(0xFF607C3C); // #607c3c – forest green
  static const Color textDark  = Color(0xFF2E3A10); // very dark for body text
  static const Color textGrey  = Color(0xFF6B7542); // olive-grey for subtitles
  static const Color cardWhite = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: limeLight,
        onSecondary: textDark,
        error: Colors.redAccent,
        onError: Colors.white,
        background: bg,
        onBackground: textDark,
        surface: cardWhite,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textDark,
        displayColor: dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: dark),
        titleTextStyle: GoogleFonts.inter(
          color: dark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: dark,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: pale,
        labelStyle: GoogleFonts.inter(color: dark, fontWeight: FontWeight.w700),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? dark : Colors.grey),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected)
                ? limeLight.withOpacity(0.5)
                : Colors.grey.withOpacity(0.2)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pale.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: limeLight.withOpacity(0.4), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: GoogleFonts.inter(color: textGrey),
        hintStyle: GoogleFonts.inter(color: textGrey.withOpacity(0.7), fontSize: 14),
        prefixIconColor: secondary,
      ),
    );
  }
}
