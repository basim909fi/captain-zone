import 'package:flutter/material.dart';
import '../theme/palette.dart';

class LegendDot extends StatelessWidget {
  final Palette palette;
  final Color color;
  final String label;

  const LegendDot({
    super.key,
    required this.palette,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
