import '../../utils/extractor.dart';

class OrderLine {
  final String? id;
  final String productId;
  final String? productName;
  final int quantity;
  final int unitPricePaisa;
  final int totalPaisa;
  final String? notes;

  const OrderLine({
    this.id,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPricePaisa,
    required this.totalPaisa,
    this.notes,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    final prod = json['product'] is Map ? json['product'] as Map : const {};
    final qty = Extractor.asInt(json['quantity'], 1);
    final price = Extractor.asInt(json['unit_price_paisa']);
    return OrderLine(
      id: json['id']?.toString() ?? json['order_item_id']?.toString(),
      productId: json['product_id']?.toString() ?? prod['id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? prod['name']?.toString() ?? 'Item',
      quantity: qty,
      unitPricePaisa: price,
      totalPaisa: Extractor.asInt(json['total_paisa'], qty * price),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
        'unit_price_paisa': unitPricePaisa,
        if (notes != null) 'notes': notes,
      };
}

class Order {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String status;
  final String channel;
  final int totalAmountPaisa;
  final int discountPaisa;
  final int deliveryFeePaisa;
  final int paidAmountPaisa;
  final List<OrderLine> lines;
  final String? notes;
  final int version;
  final DateTime? createdAt;
  final DateTime? dueDate;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.status,
    this.channel = 'offline',
    required this.totalAmountPaisa,
    this.discountPaisa = 0,
    this.deliveryFeePaisa = 0,
    this.paidAmountPaisa = 0,
    this.lines = const [],
    this.notes,
    this.version = 1,
    this.createdAt,
    this.dueDate,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final cust = json['customer'] is Map ? json['customer'] as Map : const {};
    final rawLines = json['lines'] ?? json['items'];
    List<OrderLine> parsedLines = [];
    if (rawLines is List) {
      parsedLines = rawLines.whereType<Map>().map((m) => OrderLine.fromJson(Map<String, dynamic>.from(m))).toList();
    }

    DateTime? dt;
    if (json['created_at'] != null) {
      try {
        dt = DateTime.parse(json['created_at'].toString()).toLocal();
      } catch (_) {}
    }

    DateTime? due;
    if (json['due_date'] != null) {
      try {
        due = DateTime.parse(json['due_date'].toString()).toLocal();
      } catch (_) {}
    }

    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? json['number']?.toString() ?? 'Order',
      customerId: json['customer_id']?.toString() ?? cust['id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? cust['name']?.toString() ?? 'Customer',
      status: json['status']?.toString() ?? 'draft',
      channel: json['channel']?.toString() ?? 'offline',
      totalAmountPaisa: Extractor.asInt(json['total_amount_paisa'] ?? json['total_paisa']),
      discountPaisa: Extractor.asInt(json['discount_paisa']),
      deliveryFeePaisa: Extractor.asInt(json['delivery_fee_paisa']),
      paidAmountPaisa: Extractor.asInt(json['paid_amount_paisa'] ?? json['paid_paisa']),
      lines: parsedLines,
      notes: json['notes']?.toString(),
      version: Extractor.asInt(json['version'], 1),
      createdAt: dt,
      dueDate: due,
    );
  }
}
