import 'package:flutter/material.dart';
import '../theme/palette.dart';

class StatRow extends StatelessWidget {
  final Palette palette;
  final IconData icon;
  final String label;
  final String value;

  const StatRow({
    super.key,
    required this.palette,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: palette.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: palette.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
