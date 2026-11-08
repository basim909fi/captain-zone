import 'package:flutter/material.dart';
import 'app_colors.dart';

class Palette {
  final bool isDark;

  const Palette(this.isDark);

  List<Color> get bgGradient {
    return isDark
        ? const [
            Color(0xFF10141C),
            Color(0xFF0A0D12),
          ]
        : const [
            Color(0xFFFFF8E8),
            Color(0xFFF0E4C8),
          ];
  }

  Color get navBg =>
      isDark ? const Color(0xFF10141C) : const Color(0xFFFFF2D9);

  Color get appBarBg =>
      isDark ? const Color(0xFF10141C) : const Color(0xFFFFF2D9);

  Color get dialogBg =>
      isDark ? const Color(0xFF181D26) : Colors.white;

  Color get cardBg =>
      isDark ? const Color(0xFF181D26) : Colors.white;

  Color get textPrimary =>
      isDark ? const Color(0xFFF5F7FA) : const Color(0xFF241905);

  Color get textSecondary =>
      isDark ? const Color(0xFFA0AEC0) : const Color(0xFF6B5A34);

  Color get textMuted =>
      isDark ? const Color(0xFF718096) : const Color(0xFF9C8A5E);

  Color get gold =>
      isDark ? AppColors.gold : AppColors.goldDark;

  Color get cardBorder =>
      isDark ? const Color(0xFF262D3D) : const Color(0xFFE9D9AE);

  Color get inputFill =>
      isDark ? const Color(0xFF12151C) : const Color(0xFFF4E9CC);
}

