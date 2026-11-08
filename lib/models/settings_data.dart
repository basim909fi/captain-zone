import 'package:shared_preferences/shared_preferences.dart';

class SettingsData {
  static double orderPrice = 10.0;
  static double monthlyRent = 0.0;
  static int dailyTarget = 16;
  static int monthlyGoal = 0;

  // إعدادات الشفت والتنبيهات
  static bool shiftReminderEnabled = false;
  static int shiftStartHour = 13; // 1:00 PM افتراضياً
  static int shiftStartMinute = 0;
  static int shiftEndHour = 3; // 3:00 AM فجر اليوم التالي
  static int shiftEndMinute = 0;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    orderPrice = prefs.getDouble('orderPrice') ?? orderPrice;

    monthlyRent = prefs.getDouble('monthlyRent') ??
        prefs.getDouble('dailyRent') ??
        monthlyRent;

    dailyTarget = prefs.getInt('dailyTarget') ?? dailyTarget;
    monthlyGoal = prefs.getInt('monthlyGoal') ?? monthlyGoal;

    shiftReminderEnabled = prefs.getBool('shiftReminderEnabled') ?? false;
    shiftStartHour = prefs.getInt('shiftStartHour') ?? 13;
    shiftStartMinute = prefs.getInt('shiftStartMinute') ?? 0;
    shiftEndHour = prefs.getInt('shiftEndHour') ?? 3;
    shiftEndMinute = prefs.getInt('shiftEndMinute') ?? 0;
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('orderPrice', orderPrice);
    await prefs.setDouble('monthlyRent', monthlyRent);
    await prefs.setInt('dailyTarget', dailyTarget);
    await prefs.setInt('monthlyGoal', monthlyGoal);

    await prefs.setBool('shiftReminderEnabled', shiftReminderEnabled);
    await prefs.setInt('shiftStartHour', shiftStartHour);
    await prefs.setInt('shiftStartMinute', shiftStartMinute);
    await prefs.setInt('shiftEndHour', shiftEndHour);
    await prefs.setInt('shiftEndMinute', shiftEndMinute);
  }
}
