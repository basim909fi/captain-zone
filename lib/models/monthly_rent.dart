class MonthlyRentEntry {
  final int year;
  final int month;
  double amount;

  MonthlyRentEntry({
    required this.year,
    required this.month,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'amount': amount,
    };
  }

  factory MonthlyRentEntry.fromJson(Map<String, dynamic> json) {
    return MonthlyRentEntry(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
