import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../taxes/data/repositories/tax_repository.dart';

/// Model for a statutory deadline
class StatutoryDeadline {
  final String title;
  final String description;
  final DateTime dueDate;
  final int daysUntilDue;
  final bool isPastDue;

  StatutoryDeadline({
    required this.title,
    required this.description,
    required this.dueDate,
  }) : daysUntilDue = dueDate.difference(DateTime.now()).inDays,
       isPastDue = dueDate.isBefore(DateTime.now());

  factory StatutoryDeadline.fromJson(Map<String, dynamic> json) {
    return StatutoryDeadline(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['dueDate'] is String 
        ? DateTime.parse(json['dueDate']) 
        : DateTime.now(),
    );
  }
}

/// Provider for statutory deadlines
final statutoryDeadlinesProvider = FutureProvider<List<StatutoryDeadline>>((ref) async {
  final repo = ref.watch(taxRepositoryProvider);
  final deadlines = await repo.getTaxDeadlines();
  return deadlines.map((d) => StatutoryDeadline.fromJson(d)).toList();
});
