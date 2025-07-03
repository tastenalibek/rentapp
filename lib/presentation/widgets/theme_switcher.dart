import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentapp/theme/color_selection.dart';
import 'package:rentapp/theme/theme_notifier.dart';

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return PopupMenuButton<ColorSelection>(
      icon: const Icon(Icons.color_lens_outlined),
      tooltip: 'Change Theme Color',
      onSelected: (color) => themeNotifier.updateColor(color),

      itemBuilder: (context) => ColorSelection.values.map((color) {
        return PopupMenuItem(
          value: color,
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.color, radius: 10),
              const SizedBox(width: 10),
              Text(color.label),
            ],
          ),
        );
      }).toList(),
    );
  }
}
