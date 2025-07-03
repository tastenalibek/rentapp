import 'package:flutter/material.dart';
import 'color_selection.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;
  ColorSelection _selected = ColorSelection.deepPurple;

  bool get isDarkMode => _isDarkMode;
  ColorSelection get selected => _selected;

  ThemeData get theme => ThemeData(
    brightness: _isDarkMode ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _selected.color,
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
    ),
    useMaterial3: true,
  );

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  void updateColor(ColorSelection color) {
    _selected = color;
    notifyListeners();
  }
}