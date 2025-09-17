import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF397E6F),
    onPrimary: Colors.white,
    onSurface: Colors.black,
  ),
  switchTheme: SwitchThemeData(
    trackColor: WidgetStateProperty.resolveWith<Color?>(
      (Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.grey; // Selected track color
        }
        return Colors.grey; // Default track color
      },
    ),
  ),
);
ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF397E6F),
    onPrimary: Colors.white,
    onSurface: Colors.white,
  ),
  switchTheme: SwitchThemeData(
    trackColor: WidgetStateProperty.resolveWith<Color?>(
      (Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.grey; // Selected track color
        }
        return Colors.grey; // Default track color
      },
    ),
  ),
);
