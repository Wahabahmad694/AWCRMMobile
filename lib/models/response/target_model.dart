import '../../utils/extractor.dart';

class SalesTarget {
  final String id;
  final String name;
  final String scope;
  final String? userId;
  final String? month;
  final int amountPaisa;
  final int currentSalesPaisa;
  final int version;
  final bool isArchived;

  const SalesTarget({
    required this.id,
    required this.name,
    this.scope = 'organization',
    this.userId,
    this.month,
    required this.amountPaisa,
    this.currentSalesPaisa = 0,
    this.version = 1,
    this.isArchived = false,
  });

  double get progressPercentage {
    if (amountPaisa <= 0) return 0.0;
    final pct = (currentSalesPaisa / amountPaisa) * 100;
    return pct.clamp(0.0, 100.0);
  }

  factory SalesTarget.fromJson(Map<String, dynamic> json) {
    return SalesTarget(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Monthly Target',
      scope: json['scope']?.toString() ?? 'organization',
      userId: json['user_id']?.toString(),
      month: json['month']?.toString(),
      amountPaisa: Extractor.asInt(json['amount_paisa']),
      currentSalesPaisa: Extractor.asInt(json['current_sales_paisa'] ?? json['achieved_paisa']),
      version: Extractor.asInt(json['version'], 1),
      isArchived: json['archived_at'] != null || json['is_archived'] == true,
    );
  }
}
