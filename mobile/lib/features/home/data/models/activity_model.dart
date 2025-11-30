class Activity {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  Activity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    this.metadata,
    required this.timestamp,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      metadata: json['metadata'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
