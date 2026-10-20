import '../../utils/extractor.dart';

class Payment {
  final String id;
  final String customerId;
  final String customerName;
  final String? orderId;
  final String? orderNumber;
  final int amountPaisa;
  final String method; // 'cash' | 'bank_transfer' | 'easypaisa' | 'jazzcash' | 'cheque' | 'other'
  final String? reference;
  final String status; // 'confirmed' | 'reversed'
  final DateTime? receivedAt;

  const Payment({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.orderId,
    this.orderNumber,
    required this.amountPaisa,
    required this.method,
    this.reference,
    this.status = 'confirmed',
    this.receivedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final cust = json['customer'] is Map ? json['customer'] as Map : const {};
    final ord = json['order'] is Map ? json['order'] as Map : const {};
    DateTime? dt;
    if (json['received_at'] != null || json['created_at'] != null) {
      try {
        dt = DateTime.parse((json['received_at'] ?? json['created_at']).toString()).toLocal();
      } catch (_) {}
    }
    return Payment(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? cust['id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? cust['name']?.toString() ?? 'Customer',
      orderId: json['order_id']?.toString() ?? ord['id']?.toString(),
      orderNumber: json['order_number']?.toString() ?? ord['order_number']?.toString(),
      amountPaisa: Extractor.asInt(json['amount_paisa']),
      method: json['method']?.toString() ?? 'cash',
      reference: json['reference']?.toString(),
      status: json['status']?.toString() ?? 'confirmed',
      receivedAt: dt,
    );
  }
}

class Receivable {
  final String customerId;
  final String customerName;
  final String? phone;
  final int outstandingPaisa;
  final int? invoiceCount;

  const Receivable({
    required this.customerId,
    required this.customerName,
    this.phone,
    required this.outstandingPaisa,
    this.invoiceCount,
  });

  factory Receivable.fromJson(Map<String, dynamic> json) {
    final cust = json['customer'] is Map ? json['customer'] as Map : const {};
    return Receivable(
      customerId: json['customer_id']?.toString() ?? cust['id']?.toString() ?? json['id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? cust['name']?.toString() ?? json['name']?.toString() ?? 'Customer',
      phone: json['phone']?.toString() ?? cust['phone']?.toString(),
      outstandingPaisa: Extractor.asInt(json['outstanding_paisa'] ?? json['balance_paisa']),
      invoiceCount: Extractor.asNullableInt(json['invoice_count']),
    );
  }
}

class Refund {
  final String id;
  final String customerId;
  final String? orderId;
  final int amountPaisa;
  final String method;
  final String reason;
  final DateTime? createdAt;

  const Refund({
    required this.id,
    required this.customerId,
    this.orderId,
    required this.amountPaisa,
    required this.method,
    required this.reason,
    this.createdAt,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    DateTime? dt;
    if (json['created_at'] != null) {
      try {
        dt = DateTime.parse(json['created_at'].toString()).toLocal();
      } catch (_) {}
    }
    return Refund(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      orderId: json['order_id']?.toString(),
      amountPaisa: Extractor.asInt(json['amount_paisa']),
      method: json['method']?.toString() ?? 'cash',
      reason: json['reason']?.toString() ?? '',
      createdAt: dt,
    );
  }
}
