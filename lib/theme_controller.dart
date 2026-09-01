import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._internal();
  static final ThemeController instance = ThemeController._internal();

  final ValueNotifier<ThemeMode> theme = ValueNotifier(ThemeMode.light);
  static const _themeKey = 'isDarkMode';

  // 👇 FIX: Load saved theme on app start
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    theme.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  // 👇 FIX: Save theme on toggle
  void toggleTheme(bool isDark) async {
    theme.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  bool get isDark => theme.value == ThemeMode.dark;
}