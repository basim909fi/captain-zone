class MonthStats {
  final int orders;
  final double gross;
  final double rent;
  final double companyGas;
  final double personalGas;
  final double otherExpenses;

  const MonthStats({
    required this.orders,
    required this.gross,
    required this.rent,
    required this.companyGas,
    required this.personalGas,
    required this.otherExpenses,
  });

  double get expenses {
    return rent +
        companyGas +
        personalGas +
        otherExpenses;
  }

  double get net {
    return gross - expenses;
  }
}
