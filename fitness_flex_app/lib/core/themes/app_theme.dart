import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6C63FF); // brand purple
  static const Color secondaryColor = Color(0xFFFF6584); // pink (use for nav selected)
  static const Color accentColor = Color(0xFF42A5F5);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color textColor = Color(0xFF212121);
  static const Color greyColor = Color(0xFF9E9E9E);

  // Common nav theming (used in both light & dark)
  static NavigationBarThemeData _navTheme({
    required Color background,
    required Color selected,
    required Color unselected,
    required bool dark,
  }) {
    return NavigationBarThemeData(
      height: 64,
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      indicatorColor: selected.withOpacity(dark ? .22 : .18), // pink pill
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        final isSel = states.contains(MaterialState.selected);
        return IconThemeData(
          color: isSel ? selected : unselected,
          size: 24,
        );
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        final isSel = states.contains(MaterialState.selected);
        return TextStyle(
          color: isSel ? selected : unselected,
          fontWeight: FontWeight.w600,
        );
      }),
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
      surface: Colors.white,
      onBackground: textColor,
      onSurface: textColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textColor,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
      displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: TextStyle(fontSize: 18, color: textColor),
      bodyMedium: TextStyle(fontSize: 16, color: textColor),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // 🔴 Bottom Navigation — pic #1 style
    navigationBarTheme: _navTheme(
      background: Colors.white,
      selected: secondaryColor,
      unselected: Colors.black54,
      dark: false,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1E1E1E),
    ),

    // 🔴 Bottom Navigatio
    navigationBarTheme: _navTheme(
      background: const Color(0xFF1E1E1E),
      selected: secondaryColor,
      unselected: Colors.white70,
      dark: true,
    ),
    


    
  );
}
