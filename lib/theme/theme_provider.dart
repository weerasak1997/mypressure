import 'package:flutter/material.dart';
import 'package:mypressure/theme/theme.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = lightMode;
  var _isDarkMode = false;
  ThemeData get themeData => _themeData;
  get isDarkMode => _isDarkMode;
  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
      _isDarkMode = true;
    } else {
      themeData = lightMode;
      _isDarkMode = false;
    }
  }

  void darkTheme() {
    if (isDarkMode == false) {
      themeData = darkMode;
      _isDarkMode = true;
    }
  }

  getIsDarkMode() {
    return _isDarkMode;
  }
}
