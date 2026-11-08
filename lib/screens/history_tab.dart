import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_record.dart';
import '../models/gas_entry.dart';
import '../models/other_expense.dart';
import '../theme/app_colors.dart';
import '../theme/palette.dart';
import '../utils/helpers.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';

class HistoryTab extends StatelessWidget {
  final Palette palette;
  final List<DailyRecord> records;
  final List<GasEntry> gasEntries;
  final List<OtherExpense> otherExpenses;

  final VoidCallback onAddPastDay;
  final VoidCallback onAddBulkDays;

  final Future<void> Function(DailyRecord record) onRecordLongPress;
  final Future<void> Function(GasEntry entry) onGasLongPress;
  final Future<void> Function(OtherExpense expense) onOtherLongPress;

  const HistoryTab({
    super.key,
    required this.palette,
    required this.records,
    required this.gasEntries,
    required this.otherExpenses,
    required this.onAddPastDay,
    required this.onAddBulkDays,
    required this.onRecordLongPress,
    required this.onGasLongPress,
    required this.onOtherLongPress,
  });

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: palette.textMuted),
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    required VoidCallback onLongPress,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: palette.isDark
            ? const Color(0xFF131720)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onLongPress,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = palette;

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
                sectionHeader(
                  p,
                  Icons.receipt_long,
                  'سجل الأيام',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: onAddBulkDays,
                        icon: Icon(
                          Icons.playlist_add,
                          color: p.gold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onAddPastDay,
                        icon: Icon(
                          Icons.add,
                          color: p.gold,
                          size: 18,
                        ),
                        label: Text(
                          'إضافة يوم',
                          style: TextStyle(color: p.gold),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: p.cardBorder),
                if (records.isEmpty)
                  _empty('لا توجد سجلات لهذا الشهر')
                else
                  ...records.map(
                    (record) => _card(
                      onLongPress: () => onRecordLongPress(record),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('yyyy-MM-dd').format(record.date),
                                style: TextStyle(
                                  color: p.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                record.isWorkDay
                                    ? 'يوم عمل - ${record.ordersCount} طلب'
                                    : 'يوم إجازة',
                                style: TextStyle(
                                  color: record.isWorkDay
                                      ? p.gold
                                      : AppColors.danger,
                                  fontSize: 12,
                                ),
                              ),
                              if (record.isWorkDay)
                                Text(
                                  'سعر الطلب: ${money(record.orderPrice)}',
                                  style: TextStyle(
                                    color: p.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            money(record.grossIncome),
                            style: TextStyle(
                              color: p.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            palette: p,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionHeader(
                  p,
                  Icons.local_gas_station,
                  'سجل البنزين',
                ),
                Divider(color: p.cardBorder),
                if (gasEntries.isEmpty)
                  _empty('لا توجد عمليات بنزين لهذا الشهر')
                else
                  ...gasEntries.map(
                    (entry) => _card(
                      onLongPress: () => onGasLongPress(entry),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('yyyy-MM-dd').format(entry.date),
                                style: TextStyle(
                                  color: p.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                entry.isCompany ? 'بنزين الشركة' : 'بنزين الجيب',
                                style: TextStyle(
                                  color: p.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            money(entry.amount),
                            style: TextStyle(
                              color: p.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            palette: p,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionHeader(
                  p,
                  Icons.receipt_long,
                  'سجل المصاريف الأخرى',
                ),
                Divider(color: p.cardBorder),
                if (otherExpenses.isEmpty)
                  _empty('لا توجد مصاريف إضافية لهذا الشهر')
                else
                  ...otherExpenses.map(
                    (expense) => _card(
                      onLongPress: () => onOtherLongPress(expense),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('yyyy-MM-dd').format(expense.date),
                                  style: TextStyle(
                                    color: p.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${expense.categoryIcon} ${expense.categoryLabel}${expense.description.isEmpty ? '' : ' - ${expense.description}'}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.otherExpense,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            money(expense.amount),
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
