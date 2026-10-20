import '../../utils/extractor.dart';

class Activity {
  final String id;
  final String type; // 'note' | 'call' | 'meeting' | 'follow_up' | 'whatsapp' | 'email'
  final String subject;
  final String? body;
  final String? customerId;
  final String? customerName;
  final String? orderId;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final int version;

  const Activity({
    required this.id,
    required this.type,
    required this.subject,
    this.body,
    this.customerId,
    this.customerName,
    this.orderId,
    this.dueAt,
    this.completedAt,
    this.isCompleted = false,
    this.version = 1,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) {
      if (v != null) {
        try {
          return DateTime.parse(v.toString()).toLocal();
        } catch (_) {}
      }
      return null;
    }

    final cust = json['customer'] is Map ? json['customer'] as Map : const {};
    return Activity(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'note',
      subject: json['subject']?.toString() ?? json['title']?.toString() ?? 'Activity',
      body: json['body']?.toString() ?? json['details']?.toString(),
      customerId: json['customer_id']?.toString() ?? cust['id']?.toString(),
      customerName: json['customer_name']?.toString() ?? cust['name']?.toString(),
      orderId: json['order_id']?.toString(),
      dueAt: parse(json['due_at']),
      completedAt: parse(json['completed_at']),
      isCompleted: json['completed_at'] != null || json['is_completed'] == true,
      version: Extractor.asInt(json['version'], 1),
    );
  }
}

class Reminder {
  final String id;
  final String subject;
  final String? body;
  final String? customerId;
  final String? orderId;
  final DateTime? dueAt;
  final bool isCompleted;
  final int version;

  const Reminder({
    required this.id,
    required this.subject,
    this.body,
    this.customerId,
    this.orderId,
    this.dueAt,
    this.isCompleted = false,
    this.version = 1,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) {
      if (v != null) {
        try {
          return DateTime.parse(v.toString()).toLocal();
        } catch (_) {}
      }
      return null;
    }

    return Reminder(
      id: json['id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? 'Reminder',
      body: json['body']?.toString(),
      customerId: json['customer_id']?.toString(),
      orderId: json['order_id']?.toString(),
      dueAt: parse(json['due_at']),
      isCompleted: json['completed'] == true || json['is_completed'] == true,
      version: Extractor.asInt(json['version'], 1),
    );
  }
}
