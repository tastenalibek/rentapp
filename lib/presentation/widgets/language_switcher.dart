// lib/presentation/widgets/language_switcher.dart
import 'package:flutter/material.dart';
import 'package:rentapp/main.dart'; // Import RentApp

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language, color: Colors.lightBlueAccent),
      onSelected: (Locale locale) {
        rentAppKey.currentState?.setLocale(locale); // Switch language
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: Locale('en'),
          child: Text('English 🇺🇸'),
        ),
        PopupMenuItem(
          value: Locale('ru'),
          child: Text('Русский 🇷🇺'),
        ),
        PopupMenuItem(
          value: Locale('kk'),
          child: Text('Қазақша 🇰🇿'),
        ),
      ],
    );
  }
}