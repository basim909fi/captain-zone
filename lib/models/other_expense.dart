class OtherExpense {
  DateTime date;
  double amount;
  String category;
  String description;

  OtherExpense({
    required this.date,
    required this.amount,
    required this.category,
    this.description = '',
  });

  String get categoryLabel {
    switch (category) {
      case 'traffic_fine':
        return 'مخالفة مرورية';
      case 'accident':
        return 'حادث';
      default:
        return 'أخرى';
    }
  }

  String get categoryIcon {
    switch (category) {
      case 'traffic_fine':
        return '🚔';
      case 'accident':
        return '🚗💥';
      default:
        return '📝';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'category': category,
      'description': description,
    };
  }

  factory OtherExpense.fromJson(Map<String, dynamic> json) {
    return OtherExpense(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString() ?? 'other',
      description: json['description']?.toString() ?? '',
    );
  }
}
