import 'package:flutter/material.dart';
import '../models/settings_data.dart';
import '../theme/app_colors.dart';
import '../theme/palette.dart';
import '../utils/helpers.dart';
import '../widgets/glass_card.dart';
import '../widgets/income_distribution.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_row.dart';

class StatsTab extends StatelessWidget {
  final Palette palette;
  final int selectedMonth;
  final int selectedYear;
  final List<String> monthNames;

  final int monthlyOrders;
  final double monthlyGross;
  final double monthlyRent;
  final double monthlyCompanyGas;
  final double monthlyPersonalGas;
  final double monthlyOtherExpenses;
  final double monthlyNet;
  final double previousMonthNet;

  final bool hasPreviousMonthData;
  final String projection;

  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearShift;
  final bool isGeneratingReport;
  final VoidCallback onEditRent;
  final VoidCallback onShareReport;
  final VoidCallback onSaveReport;

  const StatsTab({
    super.key,
    required this.palette,
    required this.selectedMonth,
    required this.selectedYear,
    required this.monthNames,
    required this.monthlyOrders,
    required this.monthlyGross,
    required this.monthlyRent,
    required this.monthlyCompanyGas,
    required this.monthlyPersonalGas,
    required this.monthlyOtherExpenses,
    required this.monthlyNet,
    required this.previousMonthNet,
    required this.hasPreviousMonthData,
    required this.projection,
    required this.onMonthChanged,
    required this.onYearShift,
    this.isGeneratingReport = false,
    required this.onEditRent,
    required this.onShareReport,
    required this.onSaveReport,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final netColor = monthlyNet >= 0 ? AppColors.success : AppColors.danger;

    final totalExpenses = monthlyRent +
        monthlyCompanyGas +
        monthlyPersonalGas +
        monthlyOtherExpenses;

    final hasGoal = SettingsData.monthlyGoal > 0;

    final double goalProgress = hasGoal
        ? (monthlyOrders / SettingsData.monthlyGoal).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final now = DateTime.now();

    final isCurrentMonth =
        selectedMonth == now.month && selectedYear == now.year;

    final difference = monthlyNet - previousMonthNet;

    String comparisonText;

    if (!hasPreviousMonthData) {
      comparisonText = 'لا توجد بيانات للشهر السابق';
    } else if (previousMonthNet.abs() < 0.01) {
      comparisonText =
          monthlyNet.abs() < 0.01 ? 'لا يوجد تغير' : 'لا يمكن حساب النسبة';
    } else {
      final percent = difference / previousMonthNet.abs() * 100;
      comparisonText =
          '${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(1)}%';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            palette: p,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCurrentMonth
                          ? 'إحصائيات هذا الشهر'
                          : 'إحصائيات الشهر',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'السنة السابقة',
                          icon: Icon(
                            Icons.chevron_right,
                            color: p.textSecondary,
                          ),
                          onPressed: () => onYearShift(-1),
                        ),
                        Text(
                          '$selectedYear',
                          style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'السنة التالية',
                          icon: Icon(
                            Icons.chevron_left,
                            color: p.textSecondary,
                          ),
                          onPressed: () => onYearShift(1),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<int>(
                      value: selectedMonth,
                      dropdownColor: p.dialogBg,
                      style: TextStyle(color: p.textPrimary),
                      iconEnabledColor: p.textSecondary,
                      underline: Container(
                        height: 1,
                        color: p.cardBorder,
                      ),
                      items: List.generate(
                        12,
                        (index) => index + 1,
                      ).map((month) {
                        return DropdownMenuItem<int>(
                          value: month,
                          child: Text(monthNames[month]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          onMonthChanged(value);
                        }
                      },
                    ),
                    OutlinedButton.icon(
                      onPressed: onEditRent,
                      icon: Icon(
                        Icons.edit,
                        size: 16,
                        color: p.gold,
                      ),
                      label: Text(
                        'إيجار الشهر',
                        style: TextStyle(
                          color: p.gold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(
                  color: p.cardBorder,
                  height: 26,
                ),
                StatRow(
                  palette: p,
                  icon: Icons.local_shipping,
                  label: 'إجمالي الطلبات',
                  value: '$monthlyOrders طلب',
                ),
                StatRow(
                  palette: p,
                  icon: Icons.payments,
                  label: 'إجمالي الإيرادات',
                  value: money(monthlyGross),
                ),
                StatRow(
                  palette: p,
                  icon: Icons.directions_car,
                  label: 'إيجار السيارة الشهري',
                  value: money(monthlyRent),
                ),
                StatRow(
                  palette: p,
                  icon: Icons.business,
                  label: 'بنزين الشركة',
                  value: money(monthlyCompanyGas),
                ),
                StatRow(
                  palette: p,
                  icon: Icons.local_gas_station,
                  label: 'بنزين الجيب',
                  value: money(monthlyPersonalGas),
                ),
                if (monthlyOtherExpenses > 0)
                  StatRow(
                    palette: p,
                    icon: Icons.receipt_long,
                    label: 'مصاريف أخرى',
                    value: money(monthlyOtherExpenses),
                  ),
                Divider(
                  color: p.cardBorder,
                  height: 26,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إجمالي المصروفات',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      money(totalExpenses),
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'صافي الدخل',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      money(monthlyNet),
                      style: TextStyle(
                        color: netColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                if (monthlyOrders == 0 && totalExpenses == 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.gold.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: p.gold.withValues(alpha: .25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: p.gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'لا توجد سجلات مسجلة لهذا الشهر حتى الآن. ابدأ بتسجيل الوردية اليومية أو أضف أياماً سابقة.',
                            style: TextStyle(
                              color: p.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (hasGoal)
            GlassCard(
              palette: p,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionHeader(
                    p,
                    Icons.emoji_events,
                    'هدف الشهر',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الهدف: ${SettingsData.monthlyGoal} طلب',
                        style: TextStyle(color: p.textSecondary),
                      ),
                      Text(
                        '$monthlyOrders/${SettingsData.monthlyGoal}',
                        style: TextStyle(
                          color: p.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: goalProgress,
                      minHeight: 14,
                      backgroundColor: p.cardBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        goalProgress >= 1 ? AppColors.success : p.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${(goalProgress * 100).toStringAsFixed(0)}% من الهدف',
                      style: TextStyle(
                        color: goalProgress >= 1
                            ? AppColors.success
                            : p.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (projection.isNotEmpty) ...[
            const SizedBox(height: 16),
            GlassCard(
              palette: p,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionHeader(
                    p,
                    Icons.auto_graph,
                    'التوقعات',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.otherExpense.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.otherExpense.withValues(alpha: .30),
                      ),
                    ),
                    child: Text(
                      projection,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: p.textPrimary,
                        height: 1.6,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (hasPreviousMonthData) ...[
            const SizedBox(height: 16),
            GlassCard(
              palette: p,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sectionHeader(
                    p,
                    Icons.trending_up,
                    'مقارنة بالشهر السابق',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الشهر السابق',
                            style: TextStyle(
                              color: p.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            money(previousMonthNet),
                            style: TextStyle(
                              color: p.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        difference >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: difference >= 0
                            ? AppColors.success
                            : AppColors.danger,
                        size: 26,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'هذا الشهر',
                            style: TextStyle(
                              color: p.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            money(monthlyNet),
                            style: TextStyle(
                              color: netColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      '${difference >= 0 ? '+' : ''}'
                      '${difference.toStringAsFixed(1)} ر.س '
                      '($comparisonText)',
                      style: TextStyle(
                        color: difference >= 0
                            ? AppColors.success
                            : AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          GlassCard(
            palette: p,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionHeader(
                  p,
                  Icons.pie_chart,
                  'توزيع الدخل',
                ),
                const SizedBox(height: 16),
                if (monthlyGross <= 0)
                  Center(
                    child: Text(
                      'لا توجد بيانات لهذا الشهر',
                      style: TextStyle(color: p.textMuted),
                    ),
                  )
                else
                  IncomeDistribution(
                    palette: p,
                    gross: monthlyGross,
                    rent: monthlyRent,
                    companyGas: monthlyCompanyGas,
                    personalGas: monthlyPersonalGas,
                    otherExpenses: monthlyOtherExpenses,
                    net: monthlyNet,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isGeneratingReport ? null : onShareReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.gold,
                      foregroundColor:
                          p.isDark ? const Color(0xFF10141C) : Colors.white,
                      disabledBackgroundColor: p.gold.withValues(alpha: .5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: isGeneratingReport
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: p.isDark
                                  ? const Color(0xFF10141C)
                                  : Colors.white,
                            ),
                          )
                        : const Icon(Icons.share),
                    label: Text(
                      isGeneratingReport ? 'جاري التجهيز...' : 'مشاركة',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: isGeneratingReport ? null : onSaveReport,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.gold,
                      side: BorderSide(
                        color: isGeneratingReport
                            ? p.gold.withValues(alpha: .4)
                            : p.gold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: isGeneratingReport
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: p.gold,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                      isGeneratingReport ? 'جاري الحفظ...' : 'حفظ بالمعرض',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
