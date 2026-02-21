enum SenderRole {
  USER,
  ADMIN,
}

class SupportMessage {
  final String id;
  final String ticketId;
  final SenderRole senderRole;
  final String message;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderRole,
    required this.message,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'],
      ticketId: json['ticketId'],
      senderRole: json['senderRole'] == 'ADMIN' ? SenderRole.ADMIN : SenderRole.USER,
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'senderRole': senderRole.name,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
