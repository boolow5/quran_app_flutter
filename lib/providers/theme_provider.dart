import 'dart:io';

import 'package:flutter/material.dart';
import 'package:quran_app_flutter/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  late Future<SharedPreferences> _storage;
  bool _isDarkMode = false;
  double _fontSizePercentage = Platform.isIOS ? 1.2 : 1.1; // 0.8 min, 1.5 max
  double _screenWidth = 300;
  double _screenHeight = 500;
  bool _isTablet = false;
  bool _isLandscape = false;

  bool get isDarkMode => _isDarkMode;
  double get fontSizePercentage => _fontSizePercentage;

  ThemeProvider(Future<SharedPreferences> _storage) {
    this._storage = _storage;
    _storage.then((prefs) {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _fontSizePercentage =
          prefs.getDouble('fontSizePercentage') ?? (Platform.isIOS ? 1.2 : 1.1);
      notifyListeners();
    });
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _storage.then((prefs) => prefs.setBool('isDarkMode', _isDarkMode));
    notifyListeners();
  }

  void setScreenSize(
      double width, double height, bool isTablet, bool isLandscape) {
    _screenWidth = width;
    _screenHeight = height;
    _isTablet = isTablet;
    _isLandscape = isLandscape;
    notifyListeners();
  }

  get scaleFactor {
    final double widthScale = _screenWidth / 375;
    final double heightScale = _screenHeight / 812;
    return (widthScale + heightScale) / (_isTablet && _isLandscape ? 4 : 2);
  }

  set fontSizePercentage(double percentage) {
    print("percentage: $percentage");
    if (percentage < 0.8 || percentage > 1.5) {
      print("invalid percentage: $percentage");
      return;
    }
    _fontSizePercentage = percentage;
    _storage.then(
        (prefs) => prefs.setDouble('fontSizePercentage', _fontSizePercentage));
    notifyListeners();
  }

  // fontSize takes a font size and applies the percentage to get the user desired font size
  double fontSize(double fontSize, {double? percentage}) {
    // return (fontSize * (percentage ?? _fontSizePercentage)) +
    //     ((percentage ?? _fontSizePercentage) * scaleFactor);
    return fontSize * scaleFactor * (percentage ?? _fontSizePercentage);
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
