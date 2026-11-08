import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/palette.dart';
import '../utils/helpers.dart';
import 'legend_dot.dart';

class IncomeDistribution extends StatelessWidget {
  final Palette palette;
  final double gross;
  final double rent;
  final double companyGas;
  final double personalGas;
  final double otherExpenses;
  final double net;

  const IncomeDistribution({
    super.key,
    required this.palette,
    required this.gross,
    required this.rent,
    required this.companyGas,
    required this.personalGas,
    required this.otherExpenses,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final positiveNet = net > 0 ? net : 0.0;
    final total = gross <= 0 ? 1.0 : gross;

    final parts = <Widget>[];

    void addPart(double value, Color color) {
      if (value <= 0) return;

      final flex = (value / total * 1000).round();
      if (flex <= 0) return;

      parts.add(
        Expanded(
          flex: flex,
          child: Container(color: color),
        ),
      );
    }

    addPart(positiveNet, AppColors.success);
    addPart(rent, p.gold);
    addPart(companyGas, AppColors.danger);
    addPart(personalGas, AppColors.personalGas);
    addPart(otherExpenses, AppColors.otherExpense);

    return Column(
      children: [
        if (parts.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 22,
              child: Row(children: parts),
            ),
          ),
        if (net < 0) ...[
          const SizedBox(height: 8),
          Text(
            'المصروفات أعلى من الإيرادات بمقدار ${money(net.abs())}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            LegendDot(
              palette: p,
              color: AppColors.success,
              label: 'صافي الربح',
            ),
            LegendDot(
              palette: p,
              color: p.gold,
              label: 'الإيجار',
            ),
            LegendDot(
              palette: p,
              color: AppColors.danger,
              label: 'بنزين الشركة',
            ),
            LegendDot(
              palette: p,
              color: AppColors.personalGas,
              label: 'بنزين الجيب',
            ),
            if (otherExpenses > 0)
              LegendDot(
                palette: p,
                color: AppColors.otherExpense,
                label: 'مصاريف أخرى',
              ),
          ],
        ),
      ],
    );
  }
}
