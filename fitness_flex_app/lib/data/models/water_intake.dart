class WaterIntake {
  final String id;
  final DateTime date;
  final double amount; // in liters
  final String time;

  WaterIntake({
    required this.id,
    required this.date,
    required this.amount,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'time': time,
    };
  }

  factory WaterIntake.fromMap(Map<String, dynamic> map) {
    return WaterIntake(
      id: map['id'],
      date: DateTime.parse(map['date']),
      amount: (map['amount'] as num).toDouble(), // <-- ensures double type
      time: map['time'],
    );
  }
}
