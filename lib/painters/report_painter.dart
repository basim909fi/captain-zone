import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/month_stats.dart';

class ReportPainter extends CustomPainter {
  final String monthName;
  final String previousMonthName;
  final int year;
  final MonthStats current;
  final MonthStats previous;
  final Map<int, double> dailySeries;
  final int daysInMonth;
  final bool isDark;
  final ui.Image? logoImage;

  ReportPainter({
    required this.monthName,
    required this.previousMonthName,
    required this.year,
    required this.current,
    required this.previous,
    required this.dailySeries,
    required this.daysInMonth,
    required this.isDark,
    required this.logoImage,
  });

  static const gold = Color(0xFFD4AF37);
  static const success = Color(0xFF2FBE77);
  static const danger = Color(0xFFE0555F);
  static const other = Color(0xFF4A9BD9);
  static const personalGas = Color(0xFFFF8A65);
  static const margin = 50.0;

  Color get bg1 => isDark
      ? const Color(0xFF10141C)
      : const Color(0xFFFFF8E8);

  Color get bg2 => isDark
      ? const Color(0xFF0A0D12)
      : const Color(0xFFF0E4C8);

  Color get card => isDark
      ? const Color(0xFF181D26)
      : Colors.white;

  Color get primary => isDark
      ? const Color(0xFFF5F7FA)
      : const Color(0xFF241905);

  Color get secondary => isDark
      ? const Color(0xFFA0AEC0)
      : const Color(0xFF6B5A34);

  Color get muted => isDark
      ? const Color(0xFF718096)
      : const Color(0xFF9C8A5E);

  Color get border => isDark
      ? const Color(0xFF262D3D)
      : const Color(0xFFE9D9AE);

  Color get grid => isDark
      ? const Color(0xFF262D3D).withValues(alpha: .6)
      : const Color(0xFFE9D9AE).withValues(alpha: .65);

  @override
  bool shouldRepaint(covariant ReportPainter oldDelegate) {
    return oldDelegate.current.net != current.net ||
        oldDelegate.current.orders != current.orders ||
        oldDelegate.monthName != monthName ||
        oldDelegate.year != year;
  }

  TextPainter _tp(
    String text,
    double size,
    Color color, {
    bool bold = false,
    double maxWidth = 1080,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Thmanyah',
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: ui.TextDirection.rtl,
      textAlign: TextAlign.right,
      maxLines: 10,
    );

    painter.layout(maxWidth: maxWidth);
    return painter;
  }

  void text(
    Canvas canvas,
    String value,
    Offset position,
    double size,
    Color color, {
    bool bold = false,
    bool center = false,
    bool right = false,
    double maxWidth = 1080,
  }) {
    final painter = _tp(
      value,
      size,
      color,
      bold: bold,
      maxWidth: maxWidth,
    );

    double x = position.dx;

    if (center) {
      x -= painter.width / 2;
    } else if (right) {
      x -= painter.width;
    }

    painter.paint(
      canvas,
      Offset(
        x,
        position.dy - painter.height / 2,
      ),
    );
  }

  void panel(
    Canvas canvas,
    Rect rect,
  ) {
    final rounded = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(18),
    );

    canvas.drawRRect(
      rounded,
      Paint()..color = card,
    );

    canvas.drawRRect(
      rounded,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  String amount(double value) {
    return '${value.toStringAsFixed(1)} ر.س';
  }

  String integer(double value) {
    return value.toStringAsFixed(0);
  }

  double fraction(double value, double total) {
    if (total <= 0) return 0.0;
    return (value / total).clamp(0.0, 1.0).toDouble();
  }

  double change(double value, double oldValue) {
    if (oldValue.abs() < .01) return 0;
    return (value - oldValue) / oldValue.abs() * 100;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bg1, bg2],
        ).createShader(rect),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 7),
      Paint()..color = gold,
    );

    double y = 60;

    _drawLogo(canvas, Offset(margin + 40, y + 40));

    text(
      canvas,
      'التقرير المالي الشهري',
      Offset(size.width / 2, y + 30),
      34,
      primary,
      bold: true,
      center: true,
    );

    text(
      canvas,
      'تقرير شهر $monthName $year',
      Offset(size.width / 2, y + 70),
      20,
      secondary,
      center: true,
    );

    text(
      canvas,
      DateFormat('yyyy/MM/dd').format(DateTime.now()),
      Offset(size.width - margin, y + 40),
      15,
      muted,
      right: true,
    );

    y += 110;

    canvas.drawRect(
      Rect.fromLTWH(
        margin,
        y,
        size.width - margin * 2,
        1,
      ),
      Paint()..color = gold.withValues(alpha: .4),
    );

    y += 40;

    const gap = 25.0;
    final cardWidth = (size.width - margin * 2 - gap * 3) / 4;
    const cardHeight = 175.0;

    _kpi(
      canvas,
      Rect.fromLTWH(
        margin,
        y,
        cardWidth,
        cardHeight,
      ),
      '${current.orders}',
      'إجمالي الطلبات',
      gold,
      current.orders.toDouble(),
      previous.orders.toDouble(),
    );

    _kpi(
      canvas,
      Rect.fromLTWH(
        margin + (cardWidth + gap),
        y,
        cardWidth,
        cardHeight,
      ),
      integer(current.gross),
      'إجمالي الإيرادات',
      success,
      current.gross,
      previous.gross,
    );

    _kpi(
      canvas,
      Rect.fromLTWH(
        margin + (cardWidth + gap) * 2,
        y,
        cardWidth,
        cardHeight,
      ),
      integer(current.expenses),
      'إجمالي المصروفات',
      danger,
      current.expenses,
      previous.expenses,
    );

    _kpi(
      canvas,
      Rect.fromLTWH(
        margin + (cardWidth + gap) * 3,
        y,
        cardWidth,
        cardHeight,
      ),
      integer(current.net),
      'صافي الدخل',
      current.net >= 0 ? success : danger,
      current.net,
      previous.net,
    );

    y += cardHeight + 40;

    final half = (size.width - margin * 2 - gap) / 2;
    const firstHeight = 430.0;

    final left = Rect.fromLTWH(
      margin,
      y,
      half,
      firstHeight,
    );

    final right = Rect.fromLTWH(
      margin + half + gap,
      y,
      half,
      firstHeight,
    );

    panel(canvas, left);
    panel(canvas, right);

    text(
      canvas,
      'الإيرادات خلال الشهر',
      Offset(left.center.dx, y + 32),
      20,
      primary,
      bold: true,
      center: true,
    );

    _lineChart(
      canvas,
      Rect.fromLTWH(
        left.left + 30,
        y + 70,
        left.width - 60,
        firstHeight - 110,
      ),
    );

    text(
      canvas,
      'توزيع المصروفات',
      Offset(right.center.dx, y + 32),
      20,
      primary,
      bold: true,
      center: true,
    );

    _donut(
      canvas,
      right,
      y + 70,
      firstHeight - 110,
    );

    y += firstHeight + 40;

    const secondHeight = 420.0;

    final leftSecond = Rect.fromLTWH(
      margin,
      y,
      half,
      secondHeight,
    );

    final rightSecond = Rect.fromLTWH(
      margin + half + gap,
      y,
      half,
      secondHeight,
    );

    panel(canvas, leftSecond);
    panel(canvas, rightSecond);

    text(
      canvas,
      'تفاصيل المصروفات',
      Offset(leftSecond.center.dx, y + 32),
      20,
      primary,
      bold: true,
      center: true,
    );

    _expenseTable(
      canvas,
      leftSecond.left + 25,
      y + 75,
      leftSecond.width - 50,
    );

    text(
      canvas,
      'مقارنة صافي الدخل',
      Offset(rightSecond.center.dx, y + 32),
      20,
      primary,
      bold: true,
      center: true,
    );

    _comparison(
      canvas,
      rightSecond.left + 35,
      y + 90,
      rightSecond.width - 70,
      secondHeight - 120,
    );

    y += secondHeight + 40;

    const tableHeight = 230.0;

    final tableRect = Rect.fromLTWH(
      margin,
      y,
      size.width - margin * 2,
      tableHeight,
    );

    panel(canvas, tableRect);

    text(
      canvas,
      'مقارنة شهرية',
      Offset(tableRect.center.dx, y + 32),
      20,
      primary,
      bold: true,
      center: true,
    );

    _monthlyTable(
      canvas,
      margin + 30,
      y + 70,
      size.width - margin * 2 - 60,
    );

    y += tableHeight + 40;

    const summaryHeight = 200.0;

    final summaryRect = Rect.fromLTWH(
      margin,
      y,
      size.width - margin * 2,
      summaryHeight,
    );

    panel(canvas, summaryRect);

    text(
      canvas,
      'ملخص تنفيذي',
      Offset(size.width - margin - 30, y + 35),
      20,
      gold,
      bold: true,
      right: true,
    );

    final difference = current.net - previous.net;
    final direction = difference >= 0 ? 'بارتفاع' : 'بانخفاض';

    final comparison = previous.net.abs() < .01
        ? 'لا يمكن حساب النسبة لعدم وجود صافي سابق'
        : '${change(current.net, previous.net).toStringAsFixed(1)}%';

    final summary = 'حقق النشاط خلال شهر $monthName $year '
        'إيرادات قدرها ${amount(current.gross)}، '
        'وبعد خصم المصروفات البالغة ${amount(current.expenses)} '
        'بلغ صافي الدخل ${amount(current.net)}، '
        '$direction قدره ${amount(difference.abs())} '
        'مقارنة بالشهر السابق ($comparison).';

    final summaryPainter = _tp(
      summary,
      18,
      secondary,
      maxWidth: size.width - margin * 2 - 60,
    );

    summaryPainter.paint(
      canvas,
      Offset(margin + 30, y + 75),
    );

    y += summaryHeight + 35;

    canvas.drawRect(
      Rect.fromLTWH(
        margin,
        y,
        size.width - margin * 2,
        1,
      ),
      Paint()..color = gold.withValues(alpha: .35),
    );

    y += 35;

    text(
      canvas,
      'كشف الطلبات',
      Offset(size.width / 2, y),
      20,
      primary,
      bold: true,
      center: true,
    );

    text(
      canvas,
      'تطوير: باسم محمد',
      Offset(size.width / 2, y + 32),
      16,
      muted,
      center: true,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height - 7,
        size.width,
        7,
      ),
      Paint()..color = gold,
    );
  }

  void _drawLogo(
    Canvas canvas,
    Offset center,
  ) {
    if (logoImage == null) {
      canvas.drawCircle(
        center,
        33,
        Paint()..color = gold,
      );
      canvas.drawCircle(
        center,
        23,
        Paint()..color = bg1,
      );
      canvas.drawCircle(
        center,
        11,
        Paint()..color = gold,
      );
      return;
    }

    final image = logoImage!;
    final source = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final destination = Rect.fromCenter(
      center: center,
      width: 68,
      height: 68,
    );

    canvas.save();
    canvas.clipPath(
      Path()..addOval(destination),
    );
    canvas.drawImageRect(
      image,
      source,
      destination,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }

  void _kpi(
    Canvas canvas,
    Rect rect,
    String value,
    String label,
    Color accent,
    double currentValue,
    double previousValue,
  ) {
    panel(canvas, rect);

    canvas.drawCircle(
      Offset(rect.center.dx, rect.top + 42),
      25,
      Paint()..color = accent.withValues(alpha: .18),
    );

    canvas.drawCircle(
      Offset(rect.center.dx, rect.top + 42),
      9,
      Paint()..color = accent,
    );

    text(
      canvas,
      value,
      Offset(rect.center.dx, rect.top + 96),
      26,
      primary,
      bold: true,
      center: true,
    );

    text(
      canvas,
      label,
      Offset(rect.center.dx, rect.top + 130),
      14,
      muted,
      center: true,
    );

    final hasPrevious = previousValue.abs() >= .01;
    final percent = change(currentValue, previousValue);

    text(
      canvas,
      hasPrevious
          ? '${percent >= 0 ? '▲' : '▼'} '
              '${percent.abs().toStringAsFixed(1)}%'
          : 'جديد',
      Offset(rect.center.dx, rect.top + 156),
      13,
      percent >= 0 ? success : danger,
      bold: true,
      center: true,
    );
  }

  void _lineChart(
    Canvas canvas,
    Rect rect,
  ) {
    if (dailySeries.isEmpty) {
      text(
        canvas,
        'لا توجد بيانات كافية',
        rect.center,
        16,
        muted,
        center: true,
      );
      return;
    }

    double maxValue = 1;

    for (final value in dailySeries.values) {
      if (value > maxValue) maxValue = value;
    }

    for (int i = 0; i <= 3; i++) {
      final lineY = rect.bottom - rect.height * i / 3;

      canvas.drawRect(
        Rect.fromLTWH(
          rect.left,
          lineY,
          rect.width,
          1,
        ),
        Paint()..color = grid,
      );
    }

    final points = <Offset>[];
    final divisor = daysInMonth <= 1 ? 1 : daysInMonth - 1;

    for (int day = 1; day <= daysInMonth; day++) {
      final value = dailySeries[day] ?? 0;

      final x = rect.left + rect.width * (day - 1) / divisor;

      final y = rect.bottom - value / maxValue * rect.height;

      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    final fill = Path()..moveTo(points.first.dx, rect.bottom);

    for (final point in points) {
      fill.lineTo(point.dx, point.dy);
    }

    fill
      ..lineTo(points.last.dx, rect.bottom)
      ..close();

    canvas.drawPath(
      fill,
      Paint()..color = success.withValues(alpha: .13),
    );

    final line = Path()..moveTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = success
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final int step = (daysInMonth / 6).ceil().clamp(1, daysInMonth).toInt();

    for (int day = 1; day <= daysInMonth; day += step) {
      final x = rect.left + rect.width * (day - 1) / divisor;

      text(
        canvas,
        '$day',
        Offset(x, rect.bottom + 20),
        12,
        muted,
        center: true,
      );
    }
  }

  void _donut(
    Canvas canvas,
    Rect panelRect,
    double top,
    double height,
  ) {
    final total = current.expenses;

    if (total <= 0) {
      text(
        canvas,
        'لا توجد مصروفات',
        panelRect.center,
        16,
        muted,
        center: true,
      );
      return;
    }

    final center = Offset(
      panelRect.left + panelRect.width * .34,
      top + height * .48,
    );

    final double radius = (height * .30).clamp(55.0, 110.0).toDouble();

    const stroke = 30.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = grid
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    double start = -90;

    start = _arc(
      canvas,
      center,
      radius,
      stroke,
      start,
      fraction(current.rent, total),
      gold,
    );

    start = _arc(
      canvas,
      center,
      radius,
      stroke,
      start,
      fraction(current.companyGas, total),
      danger,
    );

    start = _arc(
      canvas,
      center,
      radius,
      stroke,
      start,
      fraction(current.personalGas, total),
      personalGas,
    );

    _arc(
      canvas,
      center,
      radius,
      stroke,
      start,
      fraction(current.otherExpenses, total),
      other,
    );

    text(
      canvas,
      integer(total),
      Offset(center.dx, center.dy - 8),
      20,
      primary,
      bold: true,
      center: true,
    );

    text(
      canvas,
      'ر.س',
      Offset(center.dx, center.dy + 16),
      13,
      muted,
      center: true,
    );

    final legendX = panelRect.left + panelRect.width * .64;

    double legendY = top + height * .18;

    _legend(
      canvas,
      legendX,
      legendY,
      gold,
      'الإيجار',
      current.rent,
    );

    legendY += 55;

    _legend(
      canvas,
      legendX,
      legendY,
      danger,
      'بنزين الشركة',
      current.companyGas,
    );

    legendY += 55;

    _legend(
      canvas,
      legendX,
      legendY,
      personalGas,
      'بنزين الجيب',
      current.personalGas,
    );

    legendY += 55;

    _legend(
      canvas,
      legendX,
      legendY,
      other,
      'مصاريف أخرى',
      current.otherExpenses,
    );
  }

  double _arc(
    Canvas canvas,
    Offset center,
    double radius,
    double stroke,
    double startDegree,
    double value,
    Color color,
  ) {
    if (value <= 0) return startDegree;

    final sweep = value * 2 * 3.1415926535;
    final start = startDegree * 3.1415926535 / 180;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      start,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    return startDegree + value * 360;
  }

  void _legend(
    Canvas canvas,
    double x,
    double y,
    Color color,
    String label,
    double value,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y - 7, 14, 14),
        const Radius.circular(3),
      ),
      Paint()..color = color,
    );

    text(
      canvas,
      label,
      Offset(x + 22, y),
      13,
      secondary,
    );

    text(
      canvas,
      amount(value),
      Offset(x + 22, y + 21),
      12,
      muted,
    );
  }

  void _expenseTable(
    Canvas canvas,
    double x,
    double y,
    double width,
  ) {
    const rowHeight = 52.0;

    final items = [
      ('إيجار السيارة', current.rent, gold),
      ('بنزين الشركة', current.companyGas, danger),
      ('بنزين الجيب', current.personalGas, personalGas),
      ('مصاريف أخرى', current.otherExpenses, other),
    ];

    canvas.drawRect(
      Rect.fromLTWH(x, y, width, rowHeight),
      Paint()..color = gold.withValues(alpha: .12),
    );

    text(
      canvas,
      'البند',
      Offset(x + width - 15, y + rowHeight / 2),
      15,
      primary,
      bold: true,
      right: true,
    );

    text(
      canvas,
      'المبلغ',
      Offset(x + 15, y + rowHeight / 2),
      15,
      primary,
      bold: true,
    );

    double rowY = y + rowHeight;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(x, rowY, width, rowHeight),
          Paint()..color = grid.withValues(alpha: .3),
        );
      }

      canvas.drawCircle(
        Offset(x + width - 20, rowY + rowHeight / 2),
        5,
        Paint()..color = item.$3,
      );

      text(
        canvas,
        item.$1,
        Offset(x + width - 35, rowY + rowHeight / 2),
        14,
        secondary,
        right: true,
      );

      text(
        canvas,
        amount(item.$2),
        Offset(x + 15, rowY + rowHeight / 2),
        14,
        primary,
      );

      canvas.drawRect(
        Rect.fromLTWH(x, rowY + rowHeight - 1, width, 1),
        Paint()..color = grid,
      );

      rowY += rowHeight;
    }

    rowY += 12;

    canvas.drawRect(
      Rect.fromLTWH(x, rowY, width, 1.5),
      Paint()..color = gold,
    );

    rowY += 25;

    text(
      canvas,
      'الإجمالي',
      Offset(x + width - 15, rowY),
      16,
      primary,
      bold: true,
      right: true,
    );

    text(
      canvas,
      amount(current.expenses),
      Offset(x + 15, rowY),
      16,
      danger,
      bold: true,
    );
  }

  void _comparison(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
  ) {
    final maxValue = [
      previous.net.abs(),
      current.net.abs(),
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    final baseY = y + height * .75;
    final barWidth = width * .25;

    canvas.drawRect(
      Rect.fromLTWH(x, baseY, width, 1.5),
      Paint()..color = grid,
    );

    final previousHeight =
        previous.net.abs() / maxValue * height * .6;

    final currentHeight =
        current.net.abs() / maxValue * height * .6;

    final previousX = x + width * .17;
    final currentX = x + width * .58;

    final previousColor =
        previous.net >= 0 ? success : danger;

    final currentColor =
        current.net >= 0 ? success : danger;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          previousX,
          baseY - previousHeight,
          barWidth,
          previousHeight,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = previousColor.withValues(alpha: .65),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          currentX,
          baseY - currentHeight,
          barWidth,
          currentHeight,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = currentColor,
    );

    text(
      canvas,
      integer(previous.net),
      Offset(
        previousX + barWidth / 2,
        baseY - previousHeight - 18,
      ),
      14,
      previousColor,
      bold: true,
      center: true,
    );

    text(
      canvas,
      integer(current.net),
      Offset(
        currentX + barWidth / 2,
        baseY - currentHeight - 18,
      ),
      14,
      currentColor,
      bold: true,
      center: true,
    );

    text(
      canvas,
      previousMonthName,
      Offset(
        previousX + barWidth / 2,
        baseY + 22,
      ),
      13,
      muted,
      center: true,
    );

    text(
      canvas,
      monthName,
      Offset(
        currentX + barWidth / 2,
        baseY + 22,
      ),
      13,
      muted,
      center: true,
    );

    if (previous.net.abs() < .01) {
      text(
        canvas,
        'جديد',
        Offset(x + width / 2, y + 15),
        17,
        gold,
        bold: true,
        center: true,
      );
    } else {
      final percent = change(current.net, previous.net);

      text(
        canvas,
        '${percent >= 0 ? '▲' : '▼'} '
            '${percent.abs().toStringAsFixed(1)}%',
        Offset(x + width / 2, y + 15),
        17,
        percent >= 0 ? success : danger,
        bold: true,
        center: true,
      );
    }
  }

  void _monthlyTable(
    Canvas canvas,
    double x,
    double y,
    double width,
  ) {
    const rowHeight = 38.0;

    final col1 = x;
    final col2 = x + width * .35;
    final col3 = x + width * .65;

    canvas.drawRect(
      Rect.fromLTWH(x, y, width, rowHeight),
      Paint()..color = gold.withValues(alpha: .12),
    );

    text(
      canvas,
      'البند',
      Offset(col1 + width * .15, y + rowHeight / 2),
      14,
      primary,
      bold: true,
      center: true,
    );

    text(
      canvas,
      previousMonthName,
      Offset(col2 + width * .15, y + rowHeight / 2),
      14,
      primary,
      bold: true,
      center: true,
    );

    text(
      canvas,
      monthName,
      Offset(col3 + width * .15, y + rowHeight / 2),
      14,
      primary,
      bold: true,
      center: true,
    );

    final rows = [
      ('الطلبات', '${previous.orders}', '${current.orders}'),
      ('الإيرادات', integer(previous.gross), integer(current.gross)),
      ('المصروفات', integer(previous.expenses), integer(current.expenses)),
      ('الإيجار', integer(previous.rent), integer(current.rent)),
      ('الصافي', integer(previous.net), integer(current.net)),
    ];

    double rowY = y + rowHeight;

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final bold = row.$1 == 'الصافي';
      final color = bold ? gold : secondary;

      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(x, rowY, width, rowHeight),
          Paint()..color = grid.withValues(alpha: .25),
        );
      }

      text(
        canvas,
        row.$1,
        Offset(col1 + width * .15, rowY + rowHeight / 2),
        13,
        color,
        bold: bold,
        center: true,
      );

      text(
        canvas,
        row.$2,
        Offset(col2 + width * .15, rowY + rowHeight / 2),
        13,
        color,
        bold: bold,
        center: true,
      );

      text(
        canvas,
        row.$3,
        Offset(col3 + width * .15, rowY + rowHeight / 2),
        13,
        color,
        bold: bold,
        center: true,
      );

      canvas.drawRect(
        Rect.fromLTWH(x, rowY + rowHeight - 1, width, 1),
        Paint()..color = grid,
      );

      rowY += rowHeight;
    }
  }
}
