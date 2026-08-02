import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Palette from image ──────────────────────────────────────────────────
  static const Color ink      = Color(0xFF091413); // near-black
  static const Color forest   = Color(0xFF285A48); // dark forest green
  static const Color teal     = Color(0xFF408A71); // medium teal
  static const Color mint     = Color(0xFFB0E4CC); // light mint
  static const Color bg       = Color(0xFFF2FBF7); // very light mint bg
  static const Color cardBg   = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF091413);
  static const Color textGrey = Color(0xFF5A7A6E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: forest,
        onPrimary: Colors.white,
        secondary: teal,
        onSecondary: Colors.white,
        error: const Color(0xFFCF6679),
        onError: Colors.white,
        background: bg,
        onBackground: textDark,
        surface: cardBg,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: textDark,
        displayColor: ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: forest),
        titleTextStyle: GoogleFonts.inter(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: forest,
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
        backgroundColor: forest,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: mint,
        labelStyle: GoogleFonts.inter(color: forest, fontWeight: FontWeight.w700),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? forest : Colors.grey),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected)
                ? mint
                : Colors.grey.withOpacity(0.2)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mint.withOpacity(0.25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: mint.withOpacity(0.6), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: teal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFCF6679), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: GoogleFonts.inter(color: textGrey),
        hintStyle: GoogleFonts.inter(color: textGrey.withOpacity(0.6), fontSize: 14),
        prefixIconColor: teal,
      ),
    );
  }
}
