// Stub model for PayPeriod - minimal implementation
class PayPeriod {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  
  PayPeriod({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.status = 'OPEN',
  });
  
  factory PayPeriod.fromJson(Map<String, dynamic> json) {
    return PayPeriod(
      id: json['id'],
      name: json['name'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: json['status'] ?? 'OPEN',
    );
  }
}
