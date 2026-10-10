import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FitnessFlex visual tokens, aligned with sovanndevid.xyz.
/// All networking, application state, Firebase and exercise logic are unchanged.
class AppTheme {
  static const primaryColor = Color(0xFF171D23); // ink
  static const secondaryColor = Color(0xFFC7F681); // lime
  static const accentColor = Color(0xFF5660E9); // highlight blue
  static const backgroundColor = Color(0xFFF5F6F1);
  static const textColor = Color(0xFF171D23);
  static const greyColor = Color(0xFF60696B);
  static const borderColor = Color(0xFFD9DED7);
  static const darkSurface = Color(0xFF181F29);
  static const darkBackground = Color(0xFF101820);
  static const darkText = Color(0xFFF0F5F0);
  static const darkMuted = Color(0xFFAEBEBA);
  static const darkRaised = Color(0xFF202E35);
  static const darkBorder = Color(0xFF39484E);

  static ThemeData _build(bool dark) {
    final surface = dark ? darkSurface : Colors.white;
    final paper = dark ? darkBackground : backgroundColor;
    final ink = dark ? const Color(0xFFF5F6F1) : textColor;
    final muted = dark ? const Color(0xFFAFBDBB) : greyColor;
    final stroke = dark ? const Color(0xFF38474D) : borderColor;
    final primary = dark ? secondaryColor : primaryColor;
    final onPrimary = dark ? textColor : Colors.white;
    final scheme = ColorScheme.fromSeed(
      seedColor: secondaryColor,
      brightness: dark ? Brightness.dark : Brightness.light,
    ).copyWith(primary: primary, onPrimary: onPrimary,
      secondary: secondaryColor, onSecondary: textColor,
      surface: surface, onSurface: ink,
      onSurfaceVariant: muted, outline: stroke);
    final typography = GoogleFonts.manropeTextTheme(
      dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(bodyColor: ink, displayColor: ink);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      primaryColor: primary,
      scaffoldBackgroundColor: paper,
      textTheme: typography.copyWith(
        displayLarge: typography.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -2),
        displayMedium: typography.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
        headlineLarge: typography.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
        titleLarge: typography.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.5),
        titleMedium: typography.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyMedium: typography.bodyMedium?.copyWith(height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paper, foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false, elevation: 0,
        titleTextStyle: GoogleFonts.manrope(color: ink, fontSize: 18,
          fontWeight: FontWeight.w800, letterSpacing: -.6),
      ),
      cardTheme: CardThemeData(
        color: surface, elevation: 0, surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21),
          side: BorderSide(color: stroke),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: stroke)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: stroke)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: accentColor, width: 2)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        backgroundColor: primary, foregroundColor: onPrimary, elevation: 0,
        minimumSize: const Size(0, 50), padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      )),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: primary, foregroundColor: onPrimary,
        minimumSize: const Size(0, 50), shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        foregroundColor: ink, side: BorderSide(color: stroke),
        shape: const StadiumBorder(),
      )),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
        foregroundColor: dark ? secondaryColor : primaryColor,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      )),
      navigationBarTheme: NavigationBarThemeData(
        height: 72, backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: secondaryColor,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          size: 24, color: states.contains(WidgetState.selected) ? textColor : muted)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 11, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: states.contains(WidgetState.selected) ? ink : muted,
        )),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed, backgroundColor: surface, elevation: 0,
        selectedItemColor: primary, unselectedItemColor: muted,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      ),
      chipTheme: ChipThemeData(backgroundColor: surface, selectedColor: secondaryColor,
        side: BorderSide(color: stroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(color: ink, fontWeight: FontWeight.w700)),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accentColor),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryColor, foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? Colors.white : darkSurface,
        contentTextStyle: TextStyle(color: dark ? textColor : Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    );
  }

  static final ThemeData lightTheme = _build(false);
  static final ThemeData darkTheme = _build(true);
}
