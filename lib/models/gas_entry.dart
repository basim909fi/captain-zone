class GasEntry {
  DateTime date;
  double amount;
  bool isCompany;

  GasEntry({
    required this.date,
    required this.amount,
    required this.isCompany,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'isCompany': isCompany,
    };
  }

  factory GasEntry.fromJson(Map<String, dynamic> json) {
    return GasEntry(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isCompany: json['isCompany'] == true,
    );
  }
}
