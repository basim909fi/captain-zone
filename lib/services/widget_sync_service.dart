import 'package:flutter/services.dart';

class WidgetSyncService {
  static const MethodChannel _channel = MethodChannel('com.basim.list/widget');

  /// تحديث ودجت الشاشة الرئيسية لحظياً
  static Future<void> update() async {
    try {
      await _channel.invokeMethod('updateWidget');
    } catch (_) {
      // تجاهل إذا كانت المنصة لا تدعم الودجت أو غير مهيأة
    }
  }
}
