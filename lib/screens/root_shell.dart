import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_record.dart';
import '../models/gas_entry.dart';
import '../models/month_stats.dart';
import '../models/monthly_rent.dart';
import '../models/other_expense.dart';
import '../models/settings_data.dart';
import '../painters/report_painter.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/palette.dart';
import '../utils/helpers.dart';
import '../widgets/glass_input_decoration.dart';
import 'history_tab.dart';
import 'onboarding_screen.dart';
import 'stats_tab.dart';
import 'today_tab.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  bool isLoading = true;
  bool isDarkMode = true;
  int currentTab = 0;

  // الوردية الحالية
  bool shiftOpen = false;
  DateTime? shiftStartDate;
  int todayOrders = 0;
  double activeOrderPrice = SettingsData.orderPrice;

  // البيانات
  final List<DailyRecord> records = [];
  final List<MonthlyRentEntry> monthlyRents = [];
  final List<GasEntry> gasEntries = [];
  final List<OtherExpense> otherExpenses = [];

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  bool isGeneratingReport = false;
  ui.Image? logoImage;

  final List<String> monthNames = const [
    '',
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  Palette get palette => Palette(isDarkMode);

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _loadLogoImage();
  }

  // ============================================================
  // أدوات عامة
  // ============================================================

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    String confirmText = 'تأكيد',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: palette.dialogBg,
          title: Text(
            title,
            style: TextStyle(color: palette.textPrimary),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: palette.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<DateTime?> _pickDate({
    required DateTime initialDate,
    DateTime? lastDate,
  }) {
    final today = dateOnly(DateTime.now());
    var safeInitial = dateOnly(initialDate);

    if (safeInitial.isAfter(today)) {
      safeInitial = today;
    }

    return showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: DateTime(2023, 1, 1),
      lastDate: lastDate ?? today,
    );
  }

  bool _isFutureDate(DateTime date) {
    return dateOnly(date).isAfter(
      dateOnly(DateTime.now()),
    );
  }

  // ============================================================
  // تحميل البيانات
  // ============================================================

  Future<void> _loadLogoImage() async {
    try {
      final data = await rootBundle.load(
        'assets/icon/icon.png',
      );

      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      if (!mounted) return;

      setState(() {
        logoImage = frame.image;
      });
    } catch (_) {
      logoImage = null;
    }
  }

  Future<void> _loadAllData() async {
    try {
      await SettingsData.load();

      final prefs = await SharedPreferences.getInstance();

      isDarkMode = prefs.getBool('isDarkMode') ?? true;

      final recordsJson = prefs.getString('records');

      if (recordsJson != null && recordsJson.isNotEmpty) {
        final decoded = jsonDecode(recordsJson);

        if (decoded is List) {
          records.addAll(
            decoded.map(
              (item) => DailyRecord.fromJson(
                Map<String, dynamic>.from(item),
              ),
            ),
          );
        }
      }

      final rentsJson = prefs.getString('monthlyRents');

      if (rentsJson != null && rentsJson.isNotEmpty) {
        final decoded = jsonDecode(rentsJson);

        if (decoded is List) {
          monthlyRents.addAll(
            decoded.map(
              (item) => MonthlyRentEntry.fromJson(
                Map<String, dynamic>.from(item),
              ),
            ),
          );
        }
      }

      if (monthlyRents.isEmpty) {
        monthlyRents.add(
          MonthlyRentEntry(
            year: DateTime.now().year,
            month: DateTime.now().month,
            amount: SettingsData.monthlyRent,
          ),
        );
      }

      final gasJson = prefs.getString('gasEntries');

      if (gasJson != null && gasJson.isNotEmpty) {
        final decoded = jsonDecode(gasJson);

        if (decoded is List) {
          gasEntries.addAll(
            decoded.map(
              (item) => GasEntry.fromJson(
                Map<String, dynamic>.from(item),
              ),
            ),
          );
        }
      }

      final otherJson = prefs.getString('otherExpenses');

      if (otherJson != null && otherJson.isNotEmpty) {
        final decoded = jsonDecode(otherJson);

        if (decoded is List) {
          otherExpenses.addAll(
            decoded.map(
              (item) => OtherExpense.fromJson(
                Map<String, dynamic>.from(item),
              ),
            ),
          );
        }
      }

      final activeShiftJson = prefs.getString('activeShift');

      if (activeShiftJson != null && activeShiftJson.isNotEmpty) {
        final data = jsonDecode(activeShiftJson);

        shiftOpen = true;

        shiftStartDate = DateTime.parse(
          data['shiftStartDate'].toString(),
        );

        todayOrders = (data['ordersCount'] as num?)?.toInt() ?? 0;

        activeOrderPrice = (data['orderPrice'] as num?)?.toDouble() ??
            SettingsData.orderPrice;
      } else {
        activeOrderPrice = SettingsData.orderPrice;
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (shiftOpen && shiftStartDate != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _showSnackBar(
            'توجد وردية مفتوحة بدأت بتاريخ '
            '${DateFormat('yyyy-MM-dd').format(shiftStartDate!)}',
          );
        });
      }

      // جدولة تذكيرات الشفت إذا كانت مفعلة
      await NotificationService.scheduleShiftReminders();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showSnackBar(
        'تعذر تحميل بعض البيانات المحفوظة',
      );
    }
  }

  // ============================================================
  // الحفظ
  // ============================================================

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'records',
      jsonEncode(
        records.map((record) => record.toJson()).toList(),
      ),
    );
  }

  Future<void> _saveMonthlyRents() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'monthlyRents',
      jsonEncode(
        monthlyRents.map((rent) => rent.toJson()).toList(),
      ),
    );
  }

  Future<void> _saveGasEntries() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'gasEntries',
      jsonEncode(
        gasEntries.map((entry) => entry.toJson()).toList(),
      ),
    );
  }

  Future<void> _saveOtherExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'otherExpenses',
      jsonEncode(
        otherExpenses.map((expense) => expense.toJson()).toList(),
      ),
    );
  }

  Future<void> _saveAllData() async {
    await _saveRecords();
    await _saveMonthlyRents();
    await _saveGasEntries();
    await _saveOtherExpenses();
    await SettingsData.save();
  }

  Future<void> _saveActiveShift() async {
    if (shiftStartDate == null) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'activeShift',
      jsonEncode({
        'shiftStartDate': shiftStartDate!.toIso8601String(),
        'ordersCount': todayOrders,
        'orderPrice': activeOrderPrice,
      }),
    );
  }

  Future<void> _clearActiveShift() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeShift');
  }

  // ============================================================
  // البحث والتحديث
  // ============================================================

  DailyRecord? _recordForDate(DateTime date) {
    for (final record in records) {
      if (isSameDay(record.date, date)) {
        return record;
      }
    }

    return null;
  }

  MonthlyRentEntry? _rentForMonth(int year, int month) {
    for (final rent in monthlyRents) {
      if (rent.year == year && rent.month == month) {
        return rent;
      }
    }

    return null;
  }

  double _rentAmountForMonth(int year, int month) {
    final savedRent = _rentForMonth(year, month);

    if (savedRent != null) {
      return savedRent.amount;
    }

    final now = DateTime.now();

    if (year == now.year && month == now.month) {
      return SettingsData.monthlyRent;
    }

    return 0.0;
  }

  void _upsertRecord(DailyRecord newRecord) {
    records.removeWhere(
      (record) => isSameDay(
        record.date,
        newRecord.date,
      ),
    );

    records.add(newRecord);
  }

  void _upsertRent(MonthlyRentEntry newRent) {
    final index = monthlyRents.indexWhere(
      (rent) => rent.year == newRent.year && rent.month == newRent.month,
    );

    if (index >= 0) {
      monthlyRents[index] = newRent;
    } else {
      monthlyRents.add(newRent);
    }
  }

  // ============================================================
  // الوردية
  // ============================================================

  Future<void> startNewShift() async {
    if (shiftOpen) {
      _showSnackBar('توجد وردية مفتوحة بالفعل');
      return;
    }

    setState(() {
      shiftOpen = true;
      shiftStartDate = DateTime.now();
      todayOrders = 0;
      activeOrderPrice = SettingsData.orderPrice;
    });

    await _saveActiveShift();

    _showSnackBar('بدأت وردية جديدة');
  }

  Future<void> incrementOrders() async {
    if (!shiftOpen) {
      _showSnackBar('ابدأ الوردية أولًا');
      return;
    }

    setState(() {
      todayOrders++;
    });

    await _saveActiveShift();
  }

  Future<void> decrementOrders() async {
    if (!shiftOpen) return;

    if (todayOrders <= 0) {
      _showSnackBar('لا يمكن أن يكون عدد الطلبات أقل من صفر');
      return;
    }

    setState(() {
      todayOrders--;
    });

    await _saveActiveShift();
  }

  Future<void> editShiftDate() async {
    if (!shiftOpen || shiftStartDate == null) return;

    final result = await _pickDate(
      initialDate: shiftStartDate!,
    );

    if (result == null) return;

    setState(() {
      shiftStartDate = dateOnly(result);
    });

    await _saveActiveShift();

    _showSnackBar('تم تعديل تاريخ بداية الوردية');
  }

  Future<void> finishWorkDay() async {
    if (!shiftOpen || shiftStartDate == null) {
      return;
    }

    final confirmed = await _confirmDialog(
      title: 'حفظ وإنهاء الوردية',
      message: 'سيتم حفظ الوردية على تاريخ بدايتها:\n'
          '${DateFormat('yyyy-MM-dd').format(shiftStartDate!)}\n\n'
          'عدد الطلبات: $todayOrders\n'
          'سعر الطلب: ${money(activeOrderPrice)}\n\n'
          'هل تريد المتابعة؟',
      confirmText: 'حفظ وإنهاء',
    );

    if (!confirmed) return;

    final recordDate = dateOnly(shiftStartDate!);
    final oldRecord = _recordForDate(recordDate);

    if (oldRecord != null) {
      final replaceConfirmed = await _confirmDialog(
        title: 'استبدال سجل موجود',
        message:
            'يوجد سجل سابق لهذا التاريخ، وسيتم استبداله ببيانات الوردية الحالية. هل تريد المتابعة؟',
        confirmText: 'استبدال',
      );

      if (!replaceConfirmed) return;
    }

    final record = DailyRecord(
      date: recordDate,
      isWorkDay: true,
      ordersCount: todayOrders,
      orderPrice: activeOrderPrice,
    );

    setState(() {
      _upsertRecord(record);

      shiftOpen = false;
      shiftStartDate = null;
      todayOrders = 0;
      activeOrderPrice = SettingsData.orderPrice;
    });

    await _saveRecords();
    await _clearActiveShift();

    _showSnackBar(
      'تم حفظ الوردية ويمكنك بدء وردية جديدة الآن ✅',
    );
  }

  Future<void> markHoliday() async {
    if (shiftOpen) {
      _showSnackBar(
        'توجد وردية مفتوحة. أغلق الوردية الحالية أولًا.',
      );
      return;
    }

    final today = dateOnly(DateTime.now());
    final oldRecord = _recordForDate(today);

    if (oldRecord != null) {
      final confirmed = await _confirmDialog(
        title: 'استبدال سجل اليوم',
        message: 'يوجد سجل محفوظ لليوم. هل تريد استبداله بيوم إجازة؟',
        confirmText: 'استبدال',
      );

      if (!confirmed) return;
    } else {
      final confirmed = await _confirmDialog(
        title: 'تسجيل إجازة',
        message: 'هل تريد تسجيل اليوم كإجازة؟',
        confirmText: 'تسجيل إجازة',
      );

      if (!confirmed) return;
    }

    setState(() {
      _upsertRecord(
        DailyRecord(
          date: today,
          isWorkDay: false,
          ordersCount: 0,
          orderPrice: SettingsData.orderPrice,
        ),
      );
    });

    await _saveRecords();

    _showSnackBar('تم تسجيل اليوم كإجازة');
  }

  // ============================================================
  // الحسابات والإحصائيات
  // ============================================================

  List<DailyRecord> _recordsFor(int year, int month) {
    final list = records
        .where(
          (record) => record.date.year == year && record.date.month == month,
        )
        .toList();

    list.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return list;
  }

  List<GasEntry> _gasFor(int year, int month) {
    final list = gasEntries
        .where(
          (entry) => entry.date.year == year && entry.date.month == month,
        )
        .toList();

    list.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return list;
  }

  List<OtherExpense> _otherFor(int year, int month) {
    final list = otherExpenses
        .where(
          (expense) =>
              expense.date.year == year && expense.date.month == month,
        )
        .toList();

    list.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return list;
  }

  List<DailyRecord> get filteredRecords {
    return _recordsFor(selectedYear, selectedMonth);
  }

  List<GasEntry> get filteredGasEntries {
    return _gasFor(selectedYear, selectedMonth);
  }

  List<OtherExpense> get filteredOtherExpenses {
    return _otherFor(selectedYear, selectedMonth);
  }

  int get monthlyOrders {
    return filteredRecords.fold(
      0,
      (sum, record) => sum + record.ordersCount,
    );
  }

  double get monthlyGross {
    return filteredRecords.fold(
      0.0,
      (sum, record) => sum + record.grossIncome,
    );
  }

  double get monthlyRent {
    return _rentAmountForMonth(selectedYear, selectedMonth);
  }

  double get monthlyCompanyGas {
    return filteredGasEntries
        .where((entry) => entry.isCompany)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }

  double get monthlyPersonalGas {
    return filteredGasEntries
        .where((entry) => !entry.isCompany)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }

  double get monthlyOtherExpenses {
    return filteredOtherExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  double get monthlyNet {
    return monthlyGross -
        monthlyRent -
        monthlyCompanyGas -
        monthlyPersonalGas -
        monthlyOtherExpenses;
  }

  MonthStats _statsFor(int year, int month) {
    final targetRecords = _recordsFor(year, month);
    final targetGas = _gasFor(year, month);
    final targetOther = _otherFor(year, month);

    final orders = targetRecords.fold(
      0,
      (sum, record) => sum + record.ordersCount,
    );

    final gross = targetRecords.fold(
      0.0,
      (sum, record) => sum + record.grossIncome,
    );

    final rent = _rentAmountForMonth(year, month);

    final companyGas = targetGas
        .where((entry) => entry.isCompany)
        .fold(0.0, (sum, entry) => sum + entry.amount);

    final personalGas = targetGas
        .where((entry) => !entry.isCompany)
        .fold(0.0, (sum, entry) => sum + entry.amount);

    final otherExp = targetOther.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    return MonthStats(
      orders: orders,
      gross: gross,
      rent: rent,
      companyGas: companyGas,
      personalGas: personalGas,
      otherExpenses: otherExp,
    );
  }

  Map<int, double> _dailyGrossSeries(int year, int month) {
    final result = <int, double>{};

    for (final record in _recordsFor(year, month)) {
      result[record.date.day] =
          (result[record.date.day] ?? 0) + record.grossIncome;
    }

    return result;
  }

  MonthStats get previousMonthStats {
    var previousMonth = selectedMonth - 1;
    var previousYear = selectedYear;

    if (previousMonth < 1) {
      previousMonth = 12;
      previousYear--;
    }

    return _statsFor(previousYear, previousMonth);
  }

  bool get hasPreviousMonthData {
    var previousMonth = selectedMonth - 1;
    var previousYear = selectedYear;

    if (previousMonth < 1) {
      previousMonth = 12;
      previousYear--;
    }

    return _recordsFor(previousYear, previousMonth).isNotEmpty ||
        _gasFor(previousYear, previousMonth).isNotEmpty ||
        _otherFor(previousYear, previousMonth).isNotEmpty ||
        _rentForMonth(previousYear, previousMonth) != null;
  }

  double get previousMonthNet {
    return previousMonthStats.net;
  }

  // ============================================================
  // تغيير الشهر والسنة
  // ============================================================

  void changeMonth(int value) {
    setState(() {
      selectedMonth = value;
    });
  }

  void changeYear(int value) {
    setState(() {
      selectedYear += value;
    });
  }

  // ============================================================
  // تبديل الوضع الليلي والنهاري
  // ============================================================

  Future<void> toggleDarkMode() async {
    setState(() {
      isDarkMode = !isDarkMode;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  // ============================================================
  // الإعدادات
  // ============================================================

  Future<void> openSettingsDialog() async {
    final priceController = TextEditingController(
      text: SettingsData.orderPrice.toString(),
    );

    final rentController = TextEditingController(
      text: SettingsData.monthlyRent.toString(),
    );

    final targetController = TextEditingController(
      text: SettingsData.dailyTarget.toString(),
    );

    final goalController = TextEditingController(
      text: SettingsData.monthlyGoal.toString(),
    );

    bool reminderEnabled = SettingsData.shiftReminderEnabled;
    TimeOfDay startTime = TimeOfDay(
      hour: SettingsData.shiftStartHour,
      minute: SettingsData.shiftStartMinute,
    );
    TimeOfDay endTime = TimeOfDay(
      hour: SettingsData.shiftEndHour,
      minute: SettingsData.shiftEndMinute,
    );

    String formatTime(TimeOfDay t) {
      final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final minute = t.minute.toString().padLeft(2, '0');
      final period = t.period == DayPeriod.am ? 'ص' : 'م';
      return '$hour:$minute $period';
    }

    Future<TimeOfDay?> pickStyledTime(TimeOfDay initialTime) async {
      return showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: palette.gold,
                onPrimary: const Color(0xFF10141C),
                surface: palette.dialogBg,
                onSurface: palette.textPrimary,
              ),
              timePickerTheme: TimePickerThemeData(
                backgroundColor: palette.dialogBg,
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: palette.gold.withValues(alpha: .5)),
                ),
                dayPeriodBorderSide: BorderSide(color: palette.gold.withValues(alpha: .5)),
                dayPeriodColor: WidgetStateColor.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? palette.gold.withValues(alpha: .25)
                        : Colors.transparent),
                dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? palette.gold
                        : palette.textSecondary),
                dialHandColor: palette.gold,
                dialBackgroundColor: palette.isDark ? const Color(0xFF12151C) : const Color(0xFFF4E9CC),
                dialTextColor: WidgetStateColor.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? const Color(0xFF10141C)
                        : palette.textPrimary),
                entryModeIconColor: palette.gold,
                cancelButtonStyle: TextButton.styleFrom(foregroundColor: palette.textSecondary),
                confirmButtonStyle: ElevatedButton.styleFrom(
                  backgroundColor: palette.gold,
                  foregroundColor: const Color(0xFF10141C),
                ),
              ),
            ),
            child: Directionality(
              textDirection: ui.TextDirection.rtl,
              child: child!,
            ),
          );
        },
      );
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: palette.dialogBg,
              title: Row(
                children: [
                  Icon(Icons.settings, color: palette.gold),
                  const SizedBox(width: 8),
                  Text(
                    'الإعدادات',
                    style: TextStyle(color: palette.textPrimary),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'الأسعار والأهداف',
                      style: TextStyle(
                        color: palette.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(color: palette.textPrimary),
                      decoration: glassInputDecoration(
                        palette,
                        'سعر الطلب الواحد (ر.س)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: rentController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(color: palette.textPrimary),
                      decoration: glassInputDecoration(
                        palette,
                        'إيجار السيارة الشهري',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: palette.textPrimary),
                      decoration: glassInputDecoration(
                        palette,
                        'التارجت اليومي للطلبات',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: goalController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: palette.textPrimary),
                      decoration: glassInputDecoration(
                        palette,
                        'هدف الطلبات الشهري (0 = بدون هدف)',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Divider(color: palette.cardBorder),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notifications_active, color: palette.gold, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'تنبيهات الشفت اليومية',
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: reminderEnabled,
                          activeThumbColor: palette.gold,
                          onChanged: (val) async {
                            if (val) {
                              await NotificationService.requestPermission();
                            }
                            setDialogState(() {
                              reminderEnabled = val;
                            });
                          },
                        ),
                      ],
                    ),
                    if (reminderEnabled) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'بداية الشفت:',
                                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await pickStyledTime(startTime);
                                    if (picked != null) {
                                      setDialogState(() => startTime = picked);
                                    }
                                  },
                                  icon: Icon(Icons.access_time, size: 16, color: palette.gold),
                                  label: Text(
                                    formatTime(startTime),
                                    style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: palette.gold.withValues(alpha: .5)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'نهاية الشفت:',
                                  style: TextStyle(color: palette.textSecondary, fontSize: 13),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await pickStyledTime(endTime);
                                    if (picked != null) {
                                      setDialogState(() => endTime = picked);
                                    }
                                  },
                                  icon: Icon(Icons.access_time_filled, size: 16, color: palette.gold),
                                  label: Text(
                                    formatTime(endTime),
                                    style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: palette.gold.withValues(alpha: .5)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final orderPrice = double.tryParse(priceController.text.trim());
                    final monthlyRent = double.tryParse(rentController.text.trim());
                    final dailyTarget = int.tryParse(targetController.text.trim());
                    final monthlyGoal = int.tryParse(goalController.text.trim());

                    if (orderPrice == null ||
                        orderPrice < 0 ||
                        monthlyRent == null ||
                        monthlyRent < 0 ||
                        dailyTarget == null ||
                        dailyTarget < 0 ||
                        monthlyGoal == null ||
                        monthlyGoal < 0) {
                      _showSnackBar('تأكد من إدخال أرقام صحيحة وغير سالبة');
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      {
                        'orderPrice': orderPrice,
                        'monthlyRent': monthlyRent,
                        'dailyTarget': dailyTarget,
                        'monthlyGoal': monthlyGoal,
                        'shiftReminderEnabled': reminderEnabled,
                        'shiftStartHour': startTime.hour,
                        'shiftStartMinute': startTime.minute,
                        'shiftEndHour': endTime.hour,
                        'shiftEndMinute': endTime.minute,
                      },
                    );
                  },
                  child: const Text('حفظ الإعدادات'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final newOrderPrice = result['orderPrice'] as double;
    final newMonthlyRent = result['monthlyRent'] as double;
    final newDailyTarget = result['dailyTarget'] as int;
    final newMonthlyGoal = result['monthlyGoal'] as int;

    final newReminderEnabled = result['shiftReminderEnabled'] as bool;
    final newStartHour = result['shiftStartHour'] as int;
    final newStartMinute = result['shiftStartMinute'] as int;
    final newEndHour = result['shiftEndHour'] as int;
    final newEndMinute = result['shiftEndMinute'] as int;

    final priceChanged = newOrderPrice != SettingsData.orderPrice;
    final rentChanged = newMonthlyRent != SettingsData.monthlyRent;

    if (priceChanged || rentChanged) {
      final confirmed = await _confirmDialog(
        title: 'تنبيه تغيير الأسعار',
        message: 'سعر الطلب الجديد سيطبق على الأيام والورديات الجديدة فقط، '
            'وستبقى الأسعار القديمة كما هي.\n\n'
            'الإيجار الجديد سيطبق على الأشهر الجديدة فقط، '
            'أما الأشهر التي لها إيجار محفوظ فلن تتغير.\n\n'
            'هل تريد المتابعة؟',
        confirmText: 'تغيير الأسعار',
      );

      if (!confirmed) return;
    }

    setState(() {
      SettingsData.orderPrice = newOrderPrice;
      SettingsData.monthlyRent = newMonthlyRent;
      SettingsData.dailyTarget = newDailyTarget;
      SettingsData.monthlyGoal = newMonthlyGoal;

      SettingsData.shiftReminderEnabled = newReminderEnabled;
      SettingsData.shiftStartHour = newStartHour;
      SettingsData.shiftStartMinute = newStartMinute;
      SettingsData.shiftEndHour = newEndHour;
      SettingsData.shiftEndMinute = newEndMinute;
    });

    await SettingsData.save();
    await NotificationService.scheduleShiftReminders();

    _showSnackBar('تم حفظ الإعدادات وتحديث التنبيهات ✅');
  }

  // ============================================================
  // إيجار شهر محدد
  // ============================================================

  Future<void> editSelectedMonthRent() async {
    final existing = _rentForMonth(selectedYear, selectedMonth);

    final controller = TextEditingController(
      text: (existing?.amount ?? SettingsData.monthlyRent).toString(),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: palette.dialogBg,
          title: Text(
            'إيجار السيارة الشهري',
            style: TextStyle(color: palette.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${monthNames[selectedMonth]} $selectedYear',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(color: palette.textPrimary),
                decoration: glassInputDecoration(
                  palette,
                  'الإيجار الشهري - ر.س',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(controller.text.trim());

                if (amount == null || amount < 0) {
                  _showSnackBar('أدخل قيمة إيجار صحيحة');
                  return;
                }

                Navigator.pop(dialogContext, amount);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    final previousAmount = existing?.amount;

    if (previousAmount != null && previousAmount != result) {
      final confirmed = await _confirmDialog(
        title: 'تعديل إيجار الشهر',
        message: 'سيتم تعديل إيجار شهر '
            '${monthNames[selectedMonth]} $selectedYear '
            'إلى ${money(result)}. هل تريد المتابعة؟',
        confirmText: 'حفظ التعديل',
      );

      if (!confirmed) return;
    }

    final entry = MonthlyRentEntry(
      year: selectedYear,
      month: selectedMonth,
      amount: result,
    );

    setState(() {
      _upsertRent(entry);
    });

    await _saveMonthlyRents();

    _showSnackBar('تم حفظ إيجار الشهر');
  }

  // ============================================================
  // البنزين: إضافة وتعديل
  // ============================================================

  Future<void> openAddGasDialog({GasEntry? editingEntry}) async {
    DateTime pickedDate = editingEntry?.date ?? DateTime.now();
    bool isCompany = editingEntry?.isCompany ?? true;

    final amountController = TextEditingController(
      text: editingEntry == null ? '' : editingEntry.amount.toString(),
    );

    final result = await showDialog<GasEntry>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: palette.dialogBg,
              title: Text(
                editingEntry == null ? 'إضافة بنزين' : 'تعديل البنزين',
                style: TextStyle(color: palette.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        final res = await _pickDate(initialDate: pickedDate);
                        if (res != null) {
                          setDialogState(() {
                            pickedDate = dateOnly(res);
                          });
                        }
                      },
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(pickedDate),
                        style: TextStyle(color: palette.textPrimary),
                      ),
                    ),
                    RadioGroup<bool>(
                      groupValue: isCompany,
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => isCompany = value);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<bool>(
                            value: true,
                            activeColor: palette.gold,
                            title: Text(
                              'بنزين الشركة',
                              style: TextStyle(color: palette.textPrimary),
                            ),
                          ),
                          RadioListTile<bool>(
                            value: false,
                            activeColor: palette.gold,
                            title: Text(
                              'بنزين جيبي',
                              style: TextStyle(color: palette.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(color: palette.textPrimary),
                      decoration: glassInputDecoration(
                        palette,
                        'المبلغ - ر.س',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_isFutureDate(pickedDate)) {
                      _showSnackBar('لا يمكن تسجيل بنزين بتاريخ مستقبلي');
                      return;
                    }

                    final amount = double.tryParse(amountController.text.trim());

                    if (amount == null || amount <= 0) {
                      _showSnackBar('أدخل مبلغًا صحيحًا');
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      GasEntry(
                        date: dateOnly(pickedDate),
                        amount: amount,
                        isCompany: isCompany,
                      ),
                    );
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      if (editingEntry == null) {
        gasEntries.add(result);
      } else {
        final index = gasEntries.indexOf(editingEntry);
        if (index >= 0) {
          gasEntries[index] = result;
        }
      }
    });

    await _saveGasEntries();

    _showSnackBar(
      editingEntry == null ? 'تمت إضافة البنزين' : 'تم تعديل البنزين',
    );
  }

  // ============================================================
  // المصاريف الأخرى: إضافة وتعديل
  // ============================================================

  Future<void> openAddOtherExpenseDialog({
    OtherExpense? editingExpense,
  }) async {
    DateTime pickedDate = editingExpense?.date ?? DateTime.now();
    String selectedCategory = editingExpense?.category ?? 'traffic_fine';

    final amountController = TextEditingController(
      text: editingExpense == null ? '' : editingExpense.amount.toString(),
    );

    final descriptionController = TextEditingController(
      text: editingExpense?.description ?? '',
    );

    final result = await showDialog<OtherExpense>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: palette.dialogBg,
              title: Text(
                editingExpense == null ? 'إضافة مصروف آخر' : 'تعديل المصروف',
                style: TextStyle(color: palette.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        final res = await _pickDate(initialDate: pickedDate);
                        if (res != null) {
                          setDialogState(() {
                            pickedDate = dateOnly(res);
                          });
                        }
                      },
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(pickedDate),
                        style: TextStyle(color: palette.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<String>(
                      groupValue: selectedCategory,
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedCategory = value);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String>(
                            value: 'traffic_fine',
                            activeColor: palette.gold,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '🚔 مخالفة مرورية',
                              style: TextStyle(color: palette.textPrimary),
                            ),
                          ),
                          RadioListTile<String>(
                            value: 'accident',
                            activeColor: palette.gold,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '🚗💥 حادث',
                              style: TextStyle(color: palette.textPrimary),
                            ),
                          ),
                          RadioListTile<String>(
                            value: 'other',
                            activeColor: palette.gold,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '📝 أخرى',
                              style: TextStyle(color: palette.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedCategory == 'other')
                      TextField(
                        controller: descriptionController,
                        style: TextStyle(color: palette.textPrimary),
                        decoration: glassInputDecoration(
                          palette,
                          'وصف المصروف',
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(color: palette.textPrimary),
                      decoration: glassInputDecoration(
                        palette,
                        'المبلغ - ر.س',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_isFutureDate(pickedDate)) {
                      _showSnackBar('لا يمكن تسجيل مصروف بتاريخ مستقبلي');
                      return;
                    }

                    final amount = double.tryParse(amountController.text.trim());

                    if (amount == null || amount <= 0) {
                      _showSnackBar('أدخل مبلغًا صحيحًا');
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      OtherExpense(
                        date: dateOnly(pickedDate),
                        amount: amount,
                        category: selectedCategory,
                        description: selectedCategory == 'other'
                            ? descriptionController.text.trim()
                            : '',
                      ),
                    );
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      if (editingExpense == null) {
        otherExpenses.add(result);
      } else {
        final index = otherExpenses.indexOf(editingExpense);
        if (index >= 0) {
          otherExpenses[index] = result;
        }
      }
    });

    await _saveOtherExpenses();

    _showSnackBar(
      editingExpense == null ? 'تمت إضافة المصروف' : 'تم تعديل المصروف',
    );
  }

  // ============================================================
  // إضافة وتعديل الأيام السابقة
  // ============================================================

  Future<void> openAddPastDayDialog({DailyRecord? editingRecord}) async {
    DateTime pickedDate = editingRecord?.date ?? dateOnly(DateTime.now());
    bool isWorkDay = editingRecord?.isWorkDay ?? true;

    final ordersController = TextEditingController(
      text: editingRecord == null ? '' : editingRecord.ordersCount.toString(),
    );

    final today = dateOnly(DateTime.now());

    final result = await showDialog<DailyRecord>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isToday = isSameDay(pickedDate, today);

            return AlertDialog(
              backgroundColor: palette.dialogBg,
              title: Text(
                editingRecord == null ? 'إضافة يوم سابق' : 'تعديل اليوم',
                style: TextStyle(color: palette.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        final res = await _pickDate(
                          initialDate: pickedDate,
                          lastDate: today,
                        );

                        if (res != null) {
                          setDialogState(() {
                            pickedDate = dateOnly(res);
                          });
                        }
                      },
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(pickedDate),
                        style: TextStyle(color: palette.textPrimary),
                      ),
                    ),
                    RadioGroup<bool>(
                      groupValue: isWorkDay,
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => isWorkDay = value);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<bool>(
                            value: true,
                            activeColor: palette.gold,
                            title: Text(
                              'يوم عمل',
                              style: TextStyle(color: palette.textPrimary),
                            ),
                          ),
                          RadioListTile<bool>(
                            value: false,
                            activeColor: palette.gold,
                            title: Text(
                              'إجازة',
                              style: TextStyle(color: palette.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isWorkDay)
                      TextField(
                        controller: ordersController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: palette.textPrimary),
                        decoration: glassInputDecoration(
                          palette,
                          'عدد الطلبات',
                        ),
                      ),
                    if (isToday)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          editingRecord != null
                              ? 'أنت تعدل سجل اليوم الحالي.'
                              : shiftOpen
                                  ? 'توجد وردية مفتوحة. أضف الطلبات من شاشة الوردية.'
                                  : 'لم تبدأ وردية اليوم بعد.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isToday && editingRecord == null) {
                      _showSnackBar(
                        shiftOpen
                            ? 'أضف الطلبات من شاشة الوردية الحالية'
                            : 'ابدأ وردية اليوم أولًا',
                      );
                      return;
                    }

                    int orders = 0;

                    if (isWorkDay) {
                      final parsed = int.tryParse(ordersController.text.trim());

                      if (parsed == null || parsed < 0) {
                        _showSnackBar('أدخل عدد طلبات صحيح');
                        return;
                      }

                      orders = parsed;
                    }

                    Navigator.pop(
                      dialogContext,
                      DailyRecord(
                        date: dateOnly(pickedDate),
                        isWorkDay: isWorkDay,
                        ordersCount: orders,
                        orderPrice: editingRecord?.orderPrice ??
                            SettingsData.orderPrice,
                      ),
                    );
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final existing = _recordForDate(result.date);

    if (existing != null && existing != editingRecord) {
      final confirmed = await _confirmDialog(
        title: 'استبدال سجل موجود',
        message: 'يوجد سجل لهذا التاريخ. هل تريد استبداله؟',
        confirmText: 'استبدال',
      );

      if (!confirmed) return;
    }

    setState(() => _upsertRecord(result));
    await _saveRecords();

    _showSnackBar(
      editingRecord == null ? 'تمت إضافة اليوم' : 'تم تعديل اليوم',
    );
  }

  // ============================================================
  // إضافة الأيام بالجملة
  // ============================================================

  Future<void> openBulkAddDaysDialog() async {
    DateTime startDate = dateOnly(DateTime.now());
    final controller = TextEditingController();

    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final lines = controller.text
                .split('\n')
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .toList();

            int futureCount = 0;
            int invalidCount = 0;

            final today = dateOnly(DateTime.now());

            for (int i = 0; i < lines.length; i++) {
              final currentDate = dateOnly(
                startDate.add(Duration(days: i)),
              );

              if (_isFutureDate(currentDate) || isSameDay(currentDate, today)) {
                futureCount++;
                continue;
              }

              final value = lines[i].toLowerCase();
              final holiday = value == 'إجازة' || value == 'اجازة';

              if (!holiday) {
                final orders = int.tryParse(value);
                if (orders == null || orders < 0) {
                  invalidCount++;
                }
              }
            }

            return AlertDialog(
              backgroundColor: palette.dialogBg,
              title: Text(
                'إضافة أيام بالجملة',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        final res = await _pickDate(initialDate: startDate);
                        if (res != null) {
                          setDialogState(() {
                            startDate = dateOnly(res);
                          });
                        }
                      },
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(startDate),
                        style: TextStyle(color: palette.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'اكتب عدد الطلبات في كل سطر، أو اكتب إجازة:',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      maxLines: 8,
                      onChanged: (_) => setDialogState(() {}),
                      style: TextStyle(color: palette.textPrimary),
                      decoration: glassInputDecoration(
                        palette,
                        'مثال:\n10\n8\nإجازة\n12',
                      ),
                    ),
                    if (futureCount > 0 || invalidCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          [
                            if (futureCount > 0)
                              'سيتم تجاهل $futureCount يوم (اليوم الحالي أو مستقبلي)',
                            if (invalidCount > 0)
                              'سيتم تجاهل $invalidCount سطر غير صحيح',
                          ].join('\n'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('معالجة'),
                ),
              ],
            );
          },
        );
      },
    );

    if (accepted != true) return;

    final lines = controller.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      _showSnackBar('اكتب البيانات أولًا');
      return;
    }

    final today = dateOnly(DateTime.now());
    final newRecords = <DailyRecord>[];

    int skipped = 0;
    int replaced = 0;

    for (int i = 0; i < lines.length; i++) {
      final currentDate = dateOnly(
        startDate.add(Duration(days: i)),
      );

      if (_isFutureDate(currentDate) || isSameDay(currentDate, today)) {
        skipped++;
        continue;
      }

      final value = lines[i].toLowerCase();
      final holiday = value == 'إجازة' || value == 'اجازة';

      DailyRecord? record;

      if (holiday) {
        record = DailyRecord(
          date: currentDate,
          isWorkDay: false,
          ordersCount: 0,
          orderPrice: SettingsData.orderPrice,
        );
      } else {
        final orders = int.tryParse(value);

        if (orders == null || orders < 0) {
          skipped++;
          continue;
        }

        record = DailyRecord(
          date: currentDate,
          isWorkDay: true,
          ordersCount: orders,
          orderPrice: SettingsData.orderPrice,
        );
      }

      if (_recordForDate(currentDate) != null) {
        replaced++;
      }

      newRecords.add(record);
    }

    if (newRecords.isEmpty) {
      _showSnackBar('لم تتم إضافة أي سجل');
      return;
    }

    if (replaced > 0) {
      final confirmed = await _confirmDialog(
        title: 'استبدال سجلات موجودة',
        message: 'يوجد $replaced سجل مسجل مسبقًا. هل تريد استبدالها؟',
        confirmText: 'استبدال',
      );

      if (!confirmed) return;
    }

    setState(() {
      for (final record in newRecords) {
        _upsertRecord(record);
      }
    });

    await _saveRecords();

    _showSnackBar(
      'تمت إضافة ${newRecords.length} يوم، وتجاوز $skipped سطر',
    );
  }

  // ============================================================
  // قائمة التعديل والحذف
  // ============================================================

  Future<String?> _actionsMenu(String title) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: palette.dialogBg,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit, color: palette.gold),
                title: Text(
                  'تعديل',
                  style: TextStyle(color: palette.textPrimary),
                ),
                onTap: () => Navigator.pop(sheetContext, 'edit'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: AppColors.danger,
                ),
                title: Text(
                  'حذف',
                  style: TextStyle(color: palette.textPrimary),
                ),
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _recordActions(DailyRecord record) async {
    final action = await _actionsMenu(
      'سجل ${DateFormat('yyyy-MM-dd').format(record.date)}',
    );

    if (action == 'edit') {
      await openAddPastDayDialog(editingRecord: record);
    } else if (action == 'delete') {
      final confirmed = await _confirmDialog(
        title: 'حذف السجل',
        message: 'هل تريد حذف سجل هذا اليوم؟',
        confirmText: 'حذف',
      );

      if (!confirmed) return;

      setState(() => records.remove(record));
      await _saveRecords();
      _showSnackBar('تم حذف السجل');
    }
  }

  Future<void> _gasActions(GasEntry entry) async {
    final action = await _actionsMenu(
      'بنزين ${DateFormat('yyyy-MM-dd').format(entry.date)}',
    );

    if (action == 'edit') {
      await openAddGasDialog(editingEntry: entry);
    } else if (action == 'delete') {
      final confirmed = await _confirmDialog(
        title: 'حذف البنزين',
        message: 'هل تريد حذف عملية البنزين؟',
        confirmText: 'حذف',
      );

      if (!confirmed) return;

      setState(() => gasEntries.remove(entry));
      await _saveGasEntries();
      _showSnackBar('تم حذف عملية البنزين');
    }
  }

  Future<void> _expenseActions(OtherExpense expense) async {
    final action = await _actionsMenu(
      'مصروف ${DateFormat('yyyy-MM-dd').format(expense.date)}',
    );

    if (action == 'edit') {
      await openAddOtherExpenseDialog(editingExpense: expense);
    } else if (action == 'delete') {
      final confirmed = await _confirmDialog(
        title: 'حذف المصروف',
        message: 'هل تريد حذف المصروف؟',
        confirmText: 'حذف',
      );

      if (!confirmed) return;

      setState(() => otherExpenses.remove(expense));
      await _saveOtherExpenses();
      _showSnackBar('تم حذف المصروف');
    }
  }

  // ============================================================
  // النسخة الاحتياطية والاستعادة
  // ============================================================

  Map<String, dynamic> _backupData() {
    return {
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'records': records.map((record) => record.toJson()).toList(),
      'monthlyRents': monthlyRents.map((rent) => rent.toJson()).toList(),
      'gasEntries': gasEntries.map((entry) => entry.toJson()).toList(),
      'otherExpenses': otherExpenses.map((expense) => expense.toJson()).toList(),
      'settings': {
        'orderPrice': SettingsData.orderPrice,
        'monthlyRent': SettingsData.monthlyRent,
        'dailyTarget': SettingsData.dailyTarget,
        'monthlyGoal': SettingsData.monthlyGoal,
      },
      'activeShift': shiftOpen && shiftStartDate != null
          ? {
              'shiftStartDate': shiftStartDate!.toIso8601String(),
              'ordersCount': todayOrders,
              'orderPrice': activeOrderPrice,
            }
          : null,
    };
  }

  Future<void> _shareBackupFile() async {
    try {
      final jsonStr = jsonEncode(_backupData());
      final nowStr = DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now());
      final fileName = 'captain_backup_$nowStr.json';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json', name: fileName)],
        subject: 'نسخة احتياطية كشف الطلبات $nowStr',
      );
    } catch (_) {
      if (mounted) {
        _showSnackBar('تعذر مشاركة ملف النسخة الاحتياطية');
      }
    }
  }

  Future<void> _exportBackup() async {
    final text = jsonEncode(_backupData());

    await Clipboard.setData(
      ClipboardData(text: text),
    );

    _showSnackBar(
      'تم نسخ النسخة الاحتياطية إلى الحافظة ✅',
    );
  }

  Future<bool> _importBackup(String text) async {
    try {
      final decoded = jsonDecode(text);

      if (decoded is! Map) {
        return false;
      }

      final data = Map<String, dynamic>.from(decoded);

      if (data['records'] is! List || data['gasEntries'] is! List) {
        return false;
      }

      final importedRecords = (data['records'] as List).map((item) {
        return DailyRecord.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();

      final importedGasEntries = (data['gasEntries'] as List).map((item) {
        return GasEntry.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();

      final importedOtherExpenses =
          (data['otherExpenses'] as List? ?? []).map((item) {
        return OtherExpense.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();

      final importedRents = (data['monthlyRents'] as List? ?? []).map((item) {
        return MonthlyRentEntry.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();

      final settingsRaw = data['settings'];

      if (settingsRaw is! Map) {
        return false;
      }

      final settings = Map<String, dynamic>.from(settingsRaw);

      final importedOrderPrice = (settings['orderPrice'] as num?)?.toDouble();

      final importedMonthlyRent =
          (settings['monthlyRent'] as num?)?.toDouble() ??
              SettingsData.monthlyRent;

      final importedDailyTarget = (settings['dailyTarget'] as num?)?.toInt();

      final importedMonthlyGoal = (settings['monthlyGoal'] as num?)?.toInt();

      if (importedOrderPrice == null ||
          importedDailyTarget == null ||
          importedMonthlyGoal == null) {
        return false;
      }

      final confirmed = await _confirmDialog(
        title: 'تأكيد الاستعادة',
        message: 'سيتم استبدال جميع البيانات الحالية بالنسخة الاحتياطية. '
            'هل تريد المتابعة؟',
        confirmText: 'استعادة',
      );

      if (!confirmed) {
        return false;
      }

      setState(() {
        records
          ..clear()
          ..addAll(importedRecords);

        gasEntries
          ..clear()
          ..addAll(importedGasEntries);

        otherExpenses
          ..clear()
          ..addAll(importedOtherExpenses);

        monthlyRents
          ..clear()
          ..addAll(importedRents);

        SettingsData.orderPrice = importedOrderPrice;
        SettingsData.monthlyRent = importedMonthlyRent;
        SettingsData.dailyTarget = importedDailyTarget;
        SettingsData.monthlyGoal = importedMonthlyGoal;

        shiftOpen = false;
        shiftStartDate = null;
        todayOrders = 0;
        activeOrderPrice = SettingsData.orderPrice;

        final activeRaw = data['activeShift'];

        if (activeRaw is Map) {
          final active = Map<String, dynamic>.from(activeRaw);
          final start = active['shiftStartDate'];

          if (start != null) {
            shiftOpen = true;
            shiftStartDate = DateTime.parse(start.toString());
            todayOrders = (active['ordersCount'] as num?)?.toInt() ?? 0;
            activeOrderPrice = (active['orderPrice'] as num?)?.toDouble() ??
                SettingsData.orderPrice;
          }
        }
      });

      await _saveAllData();

      if (shiftOpen) {
        await _saveActiveShift();
      } else {
        await _clearActiveShift();
      }

      _showSnackBar(
        'تمت استعادة النسخة الاحتياطية بنجاح ✅',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> openBackupDialog() async {
    final restoreController = TextEditingController();
    bool isRestoring = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: palette.dialogBg,
              title: Row(
                children: [
                  Icon(Icons.backup_outlined, color: palette.gold),
                  const SizedBox(width: 8),
                  Text(
                    'النسخة الاحتياطية',
                    style: TextStyle(color: palette.textPrimary),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'احفظ بياناتك كملف أو انسخها كنص في مكان آمن:',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _shareBackupFile();
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('مشاركة كملف (.json)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.gold,
                        foregroundColor: palette.isDark
                            ? const Color(0xFF10141C)
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _exportBackup();
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('نسخ للحافظة كنص'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.textPrimary,
                        side: BorderSide(color: palette.cardBorder),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: palette.cardBorder),
                    const SizedBox(height: 8),
                    Text(
                      'لاستعادة نسخة سابقة، الصق نص النسخة هنا:',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: restoreController,
                      maxLines: 4,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 11,
                      ),
                      decoration: glassInputDecoration(
                        palette,
                        'الصق بيانات النسخة الاحتياطية هنا...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: isRestoring
                          ? null
                          : () async {
                              final text = restoreController.text.trim();
                              if (text.isEmpty) {
                                _showSnackBar('يرجى لصق نص النسخة أولاً');
                                return;
                              }

                              setDialogState(() => isRestoring = true);

                              final success = await _importBackup(text);

                              if (!success && mounted) {
                                _showSnackBar('النص غير صحيح أو لم تتم الاستعادة');
                              }

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            },
                      icon: isRestoring
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restore),
                      label: Text(isRestoring ? 'جاري الاستعادة...' : 'استعادة النسخة'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إغلاق'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // التوقعات
  // ============================================================

  String _smartProjection() {
    final now = DateTime.now();

    final isCurrentMonth =
        selectedMonth == now.month && selectedYear == now.year;

    if (!isCurrentMonth || monthlyOrders <= 0) {
      return '';
    }

    final daysPassed = now.day;
    final daysInMonth = DateTime(
      selectedYear,
      selectedMonth + 1,
      0,
    ).day;

    final remainingDays = daysInMonth - daysPassed;
    final averageOrders = monthlyOrders / daysPassed;
    final projectedOrders = (averageOrders * daysInMonth).round();
    final avgPrice = monthlyOrders > 0
        ? (monthlyGross / monthlyOrders)
        : SettingsData.orderPrice;
    final projectedGross = projectedOrders * avgPrice;

    final projectedGas = (monthlyCompanyGas + monthlyPersonalGas) *
        daysInMonth /
        daysPassed;

    final projectedOther =
        monthlyOtherExpenses * daysInMonth / daysPassed;

    final projectedNet =
        projectedGross - monthlyRent - projectedGas - projectedOther;

    String text = 'بمعدلك الحالي ${averageOrders.toStringAsFixed(1)} '
        'طلب/يوم، التوقع التقريبي هو $projectedOrders طلب '
        'وصافي تقريبي ${projectedNet.toStringAsFixed(0)} ر.س '
        'بنهاية الشهر.';

    if (SettingsData.monthlyGoal > 0) {
      final remaining = SettingsData.monthlyGoal - monthlyOrders;

      if (remaining > 0 && remainingDays > 0) {
        final needed = remaining / remainingDays;

        text += '\n\n🎯 تحتاج $remaining طلب إضافي خلال '
            '$remainingDays يوم، أي '
            '${needed.toStringAsFixed(1)} طلب يوميًا.';
      } else if (remaining <= 0) {
        text += '\n\n🎉 مبروك! لقد تجاوزت هدف الشهر.';
      }
    }

    return text;
  }

  // ============================================================
  // توليد التقرير والمشاركة
  // ============================================================

  Future<Uint8List> _generateReportBytes() async {
    int previousMonth = selectedMonth - 1;
    int previousYear = selectedYear;

    if (previousMonth < 1) {
      previousMonth = 12;
      previousYear--;
    }

    final current = _statsFor(selectedYear, selectedMonth);
    final previous = _statsFor(previousYear, previousMonth);
    final daily = _dailyGrossSeries(selectedYear, selectedMonth);

    final daysInMonth = DateTime(
      selectedYear,
      selectedMonth + 1,
      0,
    ).day;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const size = Size(1080, 2050);
    const exportScale = 2.5;

    final painter = ReportPainter(
      monthName: monthNames[selectedMonth],
      previousMonthName: monthNames[previousMonth],
      year: selectedYear,
      current: current,
      previous: previous,
      dailySeries: daily,
      daysInMonth: daysInMonth,
      isDark: isDarkMode,
      logoImage: logoImage,
    );

    canvas.scale(exportScale);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();

    final image = await picture.toImage(
      (size.width * exportScale).toInt(),
      (size.height * exportScale).toInt(),
    );

    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('تعذر إنشاء صورة التقرير');
    }

    return byteData.buffer.asUint8List();
  }

  Future<void> shareMonthlyReport() async {
    if (isGeneratingReport) return;

    setState(() {
      isGeneratingReport = true;
    });

    try {
      final bytes = await _generateReportBytes();

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: 'monthly_report_${selectedYear}_$selectedMonth.png',
            mimeType: 'image/png',
          ),
        ],
        subject: 'تقرير شهر ${monthNames[selectedMonth]} $selectedYear',
      );
    } catch (_) {
      if (mounted) {
        _showSnackBar('حدث خطأ أثناء إنشاء التقرير');
      }
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingReport = false;
        });
      }
    }
  }

  Future<void> saveReportToGallery() async {
    if (isGeneratingReport) return;

    setState(() {
      isGeneratingReport = true;
    });

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) {
            _showSnackBar('يلزم السماح بالوصول للصور لحفظ التقرير');
          }
          return;
        }
      }

      final bytes = await _generateReportBytes();
      await Gal.putImageBytes(
        bytes,
        name: 'monthly_report_${selectedYear}_$selectedMonth',
      );

      if (mounted) {
        _showSnackBar('تم حفظ التقرير في ألبوم الصور بنجاح ✅');
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('حدث خطأ أثناء حفظ التقرير في المعرض');
      }
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingReport = false;
        });
      }
    }
  }

  void _openGuide() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(isDark: isDarkMode),
      ),
    );
  }

  void _showAboutAppDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: palette.dialogBg,
          title: Row(
            children: [
              Icon(Icons.info_outline, color: palette.gold),
              const SizedBox(width: 8),
              Text(
                'حول التطبيق',
                style: TextStyle(color: palette.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'كشف الطلبات (Captain Zone)',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'الإصدار: 1.5.2',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'تطبيق لإدارة دورات العمل، وتتبع الطلبات اليومية وحساب الإيرادات وصافي الأرباح ومصاريف البنزين والإيجار.',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: .3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, size: 20, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'خصوصية تامة: جميع بياناتك تُحفظ محلياً على جهازك ولا تتم مشاركتها مع أي جهة خارجية.',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showPrivacyPolicyDialog();
                  },
                  icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                  label: const Text('سياسة الخصوصية الكاملة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.gold,
                    side: BorderSide(color: palette.gold.withValues(alpha: .5)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'تطوير: باسم محمد',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: palette.dialogBg,
          title: Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: palette.gold),
              const SizedBox(width: 8),
              Text(
                'سياسة الخصوصية',
                style: TextStyle(color: palette.textPrimary),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تطبيق كشف الطلبات (Captain Zone) يلتزم بأعلى معايير حماية خصوصيتك:',
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '1. تخزين محلي كامل (Local-Only):\nجميع سجلاتك المالية وتفاصيل دورات العمل وحسابات البنزين والإيجار تُحفظ محلياً على ذاكرة جهازك فقط، ولا يتم إرسالها أو مشاركتها مع أي خوادم خارجية.\n\n'
                  '2. عدم جمع البيانات الشخصية:\nالتطبيق لا يطلب ولا يجمع اسمك أو رقم هاتفك أو بريدك الإلكتروني أو موقعك الجغرافي.\n\n'
                  '3. الأذونات:\n- الوصول لمعرض الصور: يُستخدم فقط عند رغبتك الصريحة في حفظ صورة التقرير الشهري في ألبوم الصور بجهازك.\n\n'
                  '4. النسخ الاحتياطي والتحكم الكامل:\nأنت المالك الوحيد لبياناتك، ويمكنك في أي وقت تصدير نسخة احتياطية أو حذف أي سجل بضغطة زر.',
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('فهمت ذلك'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // بناء الواجهة الرئيسية
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final p = palette;

    if (isLoading) {
      return Scaffold(
        backgroundColor: p.bgGradient.first,
        body: Center(
          child: CircularProgressIndicator(color: p.gold),
        ),
      );
    }

    final tabs = [
      TodayTab(
        palette: p,
        shiftOpen: shiftOpen,
        todayOrders: todayOrders,
        shiftStartDate: shiftStartDate,
        activeOrderPrice: activeOrderPrice,
        onIncrement: incrementOrders,
        onDecrement: decrementOrders,
        onStart: startNewShift,
        onFinish: finishWorkDay,
        onHoliday: markHoliday,
        onEditDate: editShiftDate,
      ),
      StatsTab(
        palette: p,
        selectedMonth: selectedMonth,
        selectedYear: selectedYear,
        monthNames: monthNames,
        monthlyOrders: monthlyOrders,
        monthlyGross: monthlyGross,
        monthlyRent: monthlyRent,
        monthlyCompanyGas: monthlyCompanyGas,
        monthlyPersonalGas: monthlyPersonalGas,
        monthlyOtherExpenses: monthlyOtherExpenses,
        monthlyNet: monthlyNet,
        previousMonthNet: previousMonthNet,
        hasPreviousMonthData: hasPreviousMonthData,
        projection: _smartProjection(),
        onMonthChanged: changeMonth,
        onYearShift: changeYear,
        isGeneratingReport: isGeneratingReport,
        onEditRent: editSelectedMonthRent,
        onShareReport: shareMonthlyReport,
        onSaveReport: saveReportToGallery,
      ),
      HistoryTab(
        palette: p,
        records: filteredRecords,
        gasEntries: filteredGasEntries,
        otherExpenses: filteredOtherExpenses,
        onAddPastDay: () => openAddPastDayDialog(),
        onAddBulkDays: openBulkAddDaysDialog,
        onRecordLongPress: _recordActions,
        onGasLongPress: _gasActions,
        onOtherLongPress: _expenseActions,
      ),
    ];

    final themeData = ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      fontFamily: 'Thmanyah',
      textTheme: (isDarkMode ? ThemeData.dark() : ThemeData.light())
          .textTheme
          .apply(fontFamily: 'Thmanyah'),
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.gold,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        surface: p.dialogBg,
      ),
      scaffoldBackgroundColor: p.bgGradient.first,
      dialogTheme: DialogThemeData(
        backgroundColor: p.dialogBg,
      ),
      cardTheme: CardThemeData(
        color: p.cardBg,
      ),
    );

    return Theme(
      data: themeData,
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Scaffold(
        appBar: AppBar(
          backgroundColor: p.appBarBg,
          title: Text(
            'كشف الطلبات',
            style: TextStyle(color: p.textPrimary),
          ),
          iconTheme: IconThemeData(color: p.textPrimary),
          actions: [
            IconButton(
              tooltip: 'تبديل الوضع',
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: toggleDarkMode,
            ),
            PopupMenuButton<String>(
              color: p.dialogBg,
              icon: Icon(
                Icons.more_vert,
                color: p.textPrimary,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'gas':
                    openAddGasDialog();
                    break;
                  case 'expense':
                    openAddOtherExpenseDialog();
                    break;
                  case 'backup':
                    openBackupDialog();
                    break;
                  case 'settings':
                    openSettingsDialog();
                    break;
                  case 'guide':
                    _openGuide();
                    break;
                  case 'about':
                    _showAboutAppDialog();
                    break;
                  case 'privacy':
                    _showPrivacyPolicyDialog();
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'gas',
                  child: Text(
                    'إضافة بنزين',
                    style: TextStyle(color: p.textPrimary),
                  ),
                ),
                PopupMenuItem(
                  value: 'expense',
                  child: Text(
                    'إضافة مصروف آخر',
                    style: TextStyle(color: p.textPrimary),
                  ),
                ),
                PopupMenuItem(
                  value: 'backup',
                  child: Text(
                    'نسخة احتياطية',
                    style: TextStyle(color: p.textPrimary),
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Text(
                    'الإعدادات',
                    style: TextStyle(color: p.textPrimary),
                  ),
                ),
                PopupMenuItem(
                  value: 'guide',
                  child: Text(
                    'دليل الاستخدام',
                    style: TextStyle(color: p.textPrimary),
                  ),
                ),
                PopupMenuItem(
                  value: 'privacy',
                  child: Text(
                    'سياسة الخصوصية',
                    style: TextStyle(color: p.textPrimary),
                  ),
                ),
                PopupMenuItem(
                  value: 'about',
                  child: Text(
                    'حول التطبيق',
                    style: TextStyle(color: p.textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: p.bgGradient,
            ),
          ),
          child: SafeArea(
            child: IndexedStack(
              index: currentTab,
              children: tabs,
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: p.navBg,
          selectedIndex: currentTab,
          onDestinationSelected: (value) {
            setState(() {
              currentTab = value;
            });
          },
          indicatorColor: p.gold.withValues(alpha: .25),
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.today_outlined,
                color: p.textSecondary,
              ),
              selectedIcon: Icon(
                Icons.today,
                color: p.gold,
              ),
              label: 'اليوم',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.bar_chart_outlined,
                color: p.textSecondary,
              ),
              selectedIcon: Icon(
                Icons.bar_chart,
                color: p.gold,
              ),
              label: 'الإحصائيات',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.history_outlined,
                color: p.textSecondary,
              ),
              selectedIcon: Icon(
                Icons.history,
                color: p.gold,
              ),
              label: 'السجل',
            ),
          ],
        ),
      ),
    ),
  );
}
}
