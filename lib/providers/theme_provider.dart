import 'package:flutter/material.dart';
import 'package:quran_app_flutter/constants.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get theme => _isDarkMode ? darkTheme : lightTheme;

  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: DEFAULT_PRIMARY_COLOR,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: DEFAULT_BG_COLOR, // Colors.white,
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: DEFAULT_PRIMARY_COLOR,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.black,
  );
}
