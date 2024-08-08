import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(),
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
  colorScheme: ColorScheme.dark(),
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
