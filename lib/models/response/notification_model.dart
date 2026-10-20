class NotificationItem {
  final String id;
  final String title;
  final String? body;
  final String? type;
  final DateTime? readAt;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    this.body,
    this.type,
    this.readAt,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) {
      if (v != null) {
        try {
          return DateTime.parse(v.toString()).toLocal();
        } catch (_) {}
      }
      return null;
    }

    final readAt = parse(json['read_at']);
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['subject']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? json['message']?.toString(),
      type: json['type']?.toString(),
      readAt: readAt,
      isRead: readAt != null || json['is_read'] == true,
      createdAt: parse(json['created_at']),
    );
  }
}
