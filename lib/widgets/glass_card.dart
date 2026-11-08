import 'package:flutter/material.dart';
import '../theme/palette.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final Palette palette;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    required this.palette,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.isDark
            ? palette.cardBg
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: palette.isDark
                ? Colors.black.withValues(alpha: .35)
                : const Color(0xFFD8C79A).withValues(alpha: .4),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
