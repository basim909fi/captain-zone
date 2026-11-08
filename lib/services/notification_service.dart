import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/settings_data.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int shiftStartId = 101;
  static const int shiftEndId = 102;
  static const int testNotificationId = 999;

  static Future<void> init() async {
    tz.initializeTimeZones();

    // ضبط النطاق الزمني المحلي تلقائياً وفق إزاحة جهاز المستخدم
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      // البحث عن المنطقة الزمنية المناسبة أو التعيين
      final locations = tz.timeZoneDatabase.locations;
      tz.Location? matchedLocation;
      for (final loc in locations.values) {
        if (loc.currentTimeZone.offset == offset.inMilliseconds) {
          matchedLocation = loc;
          break;
        }
      }
      if (matchedLocation != null) {
        tz.setLocalLocation(matchedLocation);
        debugPrint('Matched local timezone by offset: ${matchedLocation.name}');
      } else {
        tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
      }
    } catch (e) {
      debugPrint('Timezone setup fallback to Asia/Riyadh: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
      } catch (_) {}
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    // إنشاء قناة تنبيهات عالية الأهمية
    const channel = AndroidNotificationChannel(
      'shift_reminders_channel',
      'تنبيهات الشفت والورديات',
      description: 'إشعارات لتذكير الكابتن ببدء وانتهاء شفت التوصيل',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> requestPermission() async {
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestNotificationsPermission();
      await androidImpl.requestExactAlarmsPermission();
    }
  }

  /// إرسال إشعار فوري للتأكد من عمل التنبيهات على جهاز الكابتن
  static Future<void> sendTestNotification() async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'shift_reminders_channel',
        'تنبيهات الشفت والورديات',
        channelDescription: 'إشعارات لتذكير الكابتن ببدء وانتهاء شفت التوصيل',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _notifications.show(
      testNotificationId,
      '🔔 تجربة التنبيهات - كشف الطلبات',
      'التنبيهات تعمل بنجاح على جهازك يا كابتن! جاهز لتذكيرك بوقت الشفت 🚗',
      notificationDetails,
    );
  }

  static Future<void> scheduleShiftReminders() async {
    if (!SettingsData.shiftReminderEnabled) {
      await cancelAllReminders();
      return;
    }

    await cancelAllReminders();

    // جدولة إشعار بداية الشفت
    await _scheduleDailyNotification(
      id: shiftStartId,
      hour: SettingsData.shiftStartHour,
      minute: SettingsData.shiftStartMinute,
      title: '🚗 حان وقت شفتك - بالتوفيق يا كابتن!',
      body: 'اضغط هنا لفتح الوردية ومتابعة طلبات اليوم خطوة بخطوة 🔥',
    );

    // جدولة إشعار نهاية الشفت
    await _scheduleDailyNotification(
      id: shiftEndId,
      hour: SettingsData.shiftEndHour,
      minute: SettingsData.shiftEndMinute,
      title: '🏁 قارب شفتك على الانتهاء!',
      body: 'يعطيك العافية، لا تنسَ إنهاء الوردية وتسجيل البنزين والمصاريف 📊',
    );
  }

  static Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'shift_reminders_channel',
        'تنبيهات الشفت والورديات',
        channelDescription: 'إشعارات لتذكير الكابتن ببدء وانتهاء شفت التوصيل',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Notification scheduled id: $id at $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  static Future<void> cancelAllReminders() async {
    await _notifications.cancel(shiftStartId);
    await _notifications.cancel(shiftEndId);
  }
}
