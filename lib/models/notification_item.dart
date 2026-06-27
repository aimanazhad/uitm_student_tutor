class NotificationItem {
  final String id;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'read': read,
      'createdAt': createdAt,
    };
  }

  factory NotificationItem.fromMap(String id, Map<String, dynamic> map) {
    return NotificationItem(
      id: id,
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      read: map['read'] as bool? ?? false,
      createdAt: (map['createdAt'] as DateTime?) ?? DateTime.now(),
    );
  }
}
