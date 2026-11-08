import 'package:flutter/material.dart';
import '../theme/palette.dart';

Widget sectionHeader(
  Palette p,
  IconData icon,
  String title, {
  Widget? trailing,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Icon(icon, color: p.gold, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      if (trailing != null) trailing,
    ],
  );
}
