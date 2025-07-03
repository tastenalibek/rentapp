import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentapp/theme/theme_notifier.dart';

class DarkModeSwitch extends StatelessWidget {
  const DarkModeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeNotifier>(context);
    return Switch(
      value: theme.isDarkMode,
      onChanged: (val) => theme.toggleTheme(val), // ✅ Правильно
      activeColor: theme.selected.color,
    );
  }
}
