// lib/presentation/widgets/shared_widgets.dart
import 'package:flutter/material.dart';

Widget socialLoginButton({
  required IconData icon,
  required String text,
  required Color backgroundColor,
  required Color foregroundColor,
  required Color iconColor,
  required VoidCallback? onPressed,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, color: iconColor, size: 24),
    label: Text(
      text,
      style: TextStyle(
        color: foregroundColor,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 1,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      disabledBackgroundColor: backgroundColor.withOpacity(0.5),
    ),
  );
}
