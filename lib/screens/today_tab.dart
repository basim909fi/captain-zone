import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/settings_data.dart';
import '../theme/app_colors.dart';
import '../theme/palette.dart';
import '../utils/helpers.dart';
import '../widgets/glass_card.dart';

class TodayTab extends StatefulWidget {
  final Palette palette;
  final bool shiftOpen;
  final int todayOrders;
  final DateTime? shiftStartDate;
  final double activeOrderPrice;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onStart;
  final VoidCallback onFinish;
  final VoidCallback onHoliday;
  final VoidCallback onEditDate;

  const TodayTab({
    super.key,
    required this.palette,
    required this.shiftOpen,
    required this.todayOrders,
    required this.shiftStartDate,
    required this.activeOrderPrice,
    required this.onIncrement,
    required this.onDecrement,
    required this.onStart,
    required this.onFinish,
    required this.onHoliday,
    required this.onEditDate,
  });

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _bounceController.reverse().then((_) {
      if (mounted) {
        _bounceController.forward();
      }
    });
    widget.onIncrement();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    widget.onDecrement();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;

    final target = SettingsData.dailyTarget;
    final double progress = target > 0
        ? (widget.todayOrders / target).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final displayDate = widget.shiftOpen
        ? (widget.shiftStartDate ?? DateTime.now())
        : DateTime.now();

    final todayGross = widget.todayOrders * widget.activeOrderPrice;
    final remainingOrders = target - widget.todayOrders;
    final targetAchieved = target > 0 && widget.todayOrders >= target;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          GlassCard(
            palette: p,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('yyyy-MM-dd').format(displayDate),
                      style: TextStyle(
                        color: p.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (widget.shiftOpen) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: widget.onEditDate,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.edit_calendar,
                            size: 18,
                            color: p.gold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.shiftOpen
                        ? AppColors.success.withValues(alpha: .16)
                        : p.textMuted.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.shiftOpen
                          ? AppColors.success.withValues(alpha: .5)
                          : p.textMuted.withValues(alpha: .4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.shiftOpen
                              ? AppColors.success
                              : p.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.shiftOpen
                            ? 'الوردية مفتوحة ومباشرة'
                            : 'لا توجد وردية مفتوحة',
                        style: TextStyle(
                          color: widget.shiftOpen
                              ? AppColors.success
                              : p.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: GestureDetector(
                    onTap: _handleTap,
                    onLongPress: _handleLongPress,
                    child: SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.isDark
                                  ? const Color(0xFF131720)
                                  : const Color(0xFFFBF5E8),
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: progress),
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOutCubic,
                            builder: (context, animatedValue, child) {
                              return SizedBox(
                                width: 250,
                                height: 250,
                                child: CircularProgressIndicator(
                                  value: widget.shiftOpen ? animatedValue : 0.0,
                                  strokeWidth: 18,
                                  backgroundColor: p.cardBorder,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    widget.shiftOpen
                                        ? (targetAchieved
                                            ? AppColors.success
                                            : p.gold)
                                        : p.textMuted.withValues(alpha: .3),
                                  ),
                                ),
                              );
                            },
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${widget.todayOrders}',
                                style: TextStyle(
                                  color: widget.shiftOpen
                                      ? p.textPrimary
                                      : p.textMuted,
                                  fontSize: 70,
                                  fontWeight: FontWeight.bold,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.shiftOpen
                                    ? 'من $target طلب'
                                    : 'الوردية مغلقة',
                                style: TextStyle(
                                  color: widget.shiftOpen
                                      ? p.textSecondary
                                      : p.textMuted,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.shiftOpen && targetAchieved)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: .18),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.success.withValues(alpha: .4),
                                      ),
                                    ),
                                    child: const Text(
                                      '🎉 تارجت مكتمل',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (widget.shiftOpen) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tooltip(
                        message: 'إنقاص طلب (-)',
                        child: Semantics(
                          label: 'إنقاص طلب واحد',
                          button: true,
                          child: Material(
                            color: p.isDark
                                ? const Color(0xFF232A38)
                                : const Color(0xFFEDE3D0),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                widget.onDecrement();
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: p.cardBorder,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  color: p.textPrimary,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 28),
                      Tooltip(
                        message: 'إضافة طلب (+)',
                        child: Semantics(
                          label: 'إضافة طلب واحد',
                          button: true,
                          child: Material(
                            color: p.gold,
                            shape: const CircleBorder(),
                            elevation: 4,
                            shadowColor: p.gold.withValues(alpha: 0.4),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _handleTap,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: p.isDark
                                      ? const Color(0xFF10141C)
                                      : Colors.white,
                                  size: 34,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  widget.shiftOpen
                      ? 'اضغط للدخول أو استخدم الأزرار للتحكم'
                      : 'ابدأ الوردية لتسجيل الطلبات',
                  style: TextStyle(
                    color: p.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.shiftOpen) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: p.isDark
                          ? Colors.white.withValues(alpha: .04)
                          : Colors.black.withValues(alpha: .03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'الدخل المتوقع اليوم',
                              style: TextStyle(
                                color: p.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              money(todayGross),
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 34,
                          color: p.cardBorder,
                        ),
                        Column(
                          children: [
                            Text(
                              'حالة التارجت',
                              style: TextStyle(
                                color: p.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              targetAchieved
                                  ? 'مكتمل ✅'
                                  : 'متبقي $remainingOrders طلب',
                              style: TextStyle(
                                color: targetAchieved
                                    ? AppColors.success
                                    : p.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: widget.onFinish,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'حفظ وإنهاء الوردية',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.gold,
                        foregroundColor:
                            p.isDark ? const Color(0xFF10141C) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: widget.onStart,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        'بدء وردية جديدة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.gold,
                        foregroundColor:
                            p.isDark ? const Color(0xFF10141C) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: widget.onHoliday,
                      icon: const Icon(
                        Icons.beach_access,
                        color: AppColors.danger,
                      ),
                      label: const Text(
                        'تسجيل اليوم كإجازة',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.danger,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
