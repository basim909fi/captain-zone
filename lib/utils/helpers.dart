import 'package:intl/intl.dart';

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
}

DateTime dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String money(double value) {
  return '${value.toStringAsFixed(1)} ر.س';
}

String formatDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}
