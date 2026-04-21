import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFF9E6),
        primaryColor: const Color(0xFFFFD700),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFFFFC107),
          surface: Color(0xFFFFFFFF),
          background: Color(0xFFFFF9E6),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF9E6),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF2D2D2D)),
          titleTextStyle: TextStyle(
            fontFamily: 'Pacifico',
            fontSize: 26,
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.w400,
          ),
        ),
        cardColor: Colors.white,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFD700),
          foregroundColor: Color(0xFF2D2D2D),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF2D2D2D), fontFamily: 'Inter'),
          bodyMedium: TextStyle(color: Color(0xFF555555), fontFamily: 'Inter'),
          titleLarge: TextStyle(
            color: Color(0xFF2D2D2D),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontFamily: 'Inter'),
        ),
        dividerColor: Color(0xFFEEEEEE),
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        primaryColor: const Color(0xFFFFD700),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFFFFC107),
          surface: Color(0xFF2C2C2C),
          background: Color(0xFF1A1A1A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFF5F5F5)),
          titleTextStyle: TextStyle(
            fontFamily: 'Pacifico',
            fontSize: 26,
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.w400,
          ),
        ),
        cardColor: const Color(0xFF2C2C2C),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFD700),
          foregroundColor: Color(0xFF1A1A1A),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF5F5F5)),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFF5F5F5), fontFamily: 'Inter'),
          bodyMedium: TextStyle(color: Color(0xFFBBBBBB), fontFamily: 'Inter'),
          titleLarge: TextStyle(
            color: Color(0xFFF5F5F5),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          hintStyle: TextStyle(color: Color(0xFF666666), fontFamily: 'Inter'),
        ),
        dividerColor: Color(0xFF333333),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF222222),
        ),
      );
}
