import '../../utils/extractor.dart';

class Customer {
  final String id;
  final String name;
  final String? code;
  final String type; // 'lead' | 'customer'
  final String? businessName;
  final String? phone;
  final String? email;
  final String? city;
  final String? area;
  final String? address;
  final List<String> tags;
  final int creditLimitPaisa;
  final int balancePaisa;
  final String? assignedToId;
  final String? notes;
  final int version;
  final bool isArchived;
  final DateTime? createdAt;

  const Customer({
    required this.id,
    required this.name,
    this.code,
    this.type = 'customer',
    this.businessName,
    this.phone,
    this.email,
    this.city,
    this.area,
    this.address,
    this.tags = const [],
    this.creditLimitPaisa = 0,
    this.balancePaisa = 0,
    this.assignedToId,
    this.notes,
    this.version = 1,
    this.isArchived = false,
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    DateTime? dt;
    if (json['created_at'] != null) {
      try {
        dt = DateTime.parse(json['created_at'].toString()).toLocal();
      } catch (_) {}
    }

    final rawTags = json['tags'];
    List<String> parsedTags = [];
    if (rawTags is List) {
      parsedTags = rawTags.map((e) => e.toString()).toList();
    } else if (rawTags is String && rawTags.isNotEmpty) {
      parsedTags = rawTags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Customer',
      code: json['code']?.toString(),
      type: json['type']?.toString() ?? 'customer',
      businessName: json['business_name']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      city: json['city']?.toString(),
      area: json['area']?.toString(),
      address: json['address']?.toString(),
      tags: parsedTags,
      creditLimitPaisa: Extractor.asInt(json['credit_limit_paisa']),
      balancePaisa: Extractor.asInt(json['balance_paisa']),
      assignedToId: json['assigned_to_id']?.toString(),
      notes: json['notes']?.toString(),
      version: Extractor.asInt(json['version'], 1),
      isArchived: json['archived_at'] != null || json['is_archived'] == true,
      createdAt: dt,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        if (code != null) 'code': code,
        'type': type,
        if (businessName != null) 'business_name': businessName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (city != null) 'city': city,
        if (area != null) 'area': area,
        if (address != null) 'address': address,
        if (tags.isNotEmpty) 'tags': tags,
        'credit_limit_paisa': creditLimitPaisa,
        if (assignedToId != null) 'assigned_to_id': assignedToId,
        if (notes != null) 'notes': notes,
      };
}

class CustomerLedgerEntry {
  final String id;
  final String type; // 'invoice' | 'payment' | 'adjustment'
  final String? reference;
  final int debitPaisa;
  final int creditPaisa;
  final int balancePaisa;
  final DateTime? date;

  const CustomerLedgerEntry({
    required this.id,
    required this.type,
    this.reference,
    this.debitPaisa = 0,
    this.creditPaisa = 0,
    this.balancePaisa = 0,
    this.date,
  });

  factory CustomerLedgerEntry.fromJson(Map<String, dynamic> json) {
    DateTime? dt;
    if (json['date'] != null || json['created_at'] != null) {
      try {
        dt = DateTime.parse((json['date'] ?? json['created_at']).toString()).toLocal();
      } catch (_) {}
    }
    return CustomerLedgerEntry(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'entry',
      reference: json['reference']?.toString(),
      debitPaisa: Extractor.asInt(json['debit_paisa']),
      creditPaisa: Extractor.asInt(json['credit_paisa']),
      balancePaisa: Extractor.asInt(json['balance_paisa']),
      date: dt,
    );
  }
}
