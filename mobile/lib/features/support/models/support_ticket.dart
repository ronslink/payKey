import 'support_message.dart';

enum TicketStatus {
  OPEN,
  IN_PROGRESS,
  RESOLVED,
  CLOSED,
}

enum TicketPriority {
  LOW,
  MEDIUM,
  HIGH,
  URGENT,
}

enum TicketCategory {
  PAYROLL,
  TAXES,
  WALLET,
  ACCOUNT,
  OTHER,
}

class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final TicketCategory category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SupportMessage> messages;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      userId: json['userId'] ?? '',
      subject: json['subject'] ?? 'No Subject',
      description: json['description'] ?? '',
      status: _parseStatus(json['status']),
      priority: _parsePriority(json['priority']),
      category: _parseCategory(json['category']),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => SupportMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static TicketStatus _parseStatus(String? status) {
    switch (status) {
      case 'IN_PROGRESS':
        return TicketStatus.IN_PROGRESS;
      case 'RESOLVED':
        return TicketStatus.RESOLVED;
      case 'CLOSED':
        return TicketStatus.CLOSED;
      case 'OPEN':
      default:
        return TicketStatus.OPEN;
    }
  }

  static TicketPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'MEDIUM':
        return TicketPriority.MEDIUM;
      case 'HIGH':
        return TicketPriority.HIGH;
      case 'URGENT':
        return TicketPriority.URGENT;
      case 'LOW':
      default:
        return TicketPriority.LOW;
    }
  }

  static TicketCategory _parseCategory(String? category) {
    switch (category) {
      case 'PAYROLL':
        return TicketCategory.PAYROLL;
      case 'TAXES':
        return TicketCategory.TAXES;
      case 'WALLET':
        return TicketCategory.WALLET;
      case 'ACCOUNT':
        return TicketCategory.ACCOUNT;
      case 'OTHER':
      default:
        return TicketCategory.OTHER;
    }
  }
}
