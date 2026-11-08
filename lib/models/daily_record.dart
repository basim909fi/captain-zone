import 'settings_data.dart';

class DailyRecord {
  DateTime date;
  bool isWorkDay;
  int ordersCount;
  double orderPrice;

  DailyRecord({
    required this.date,
    required this.isWorkDay,
    this.ordersCount = 0,
    double? orderPrice,
  }) : orderPrice = orderPrice ?? SettingsData.orderPrice;

  double get grossIncome {
    return isWorkDay ? ordersCount * orderPrice : 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'isWorkDay': isWorkDay,
      'ordersCount': ordersCount,
      'orderPrice': orderPrice,
    };
  }

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      isWorkDay: json['isWorkDay'] == true,
      ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
      orderPrice: (json['orderPrice'] as num?)?.toDouble(),
    );
  }
}
