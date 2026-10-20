import '../../utils/extractor.dart';

class StockLevel {
  final String productId;
  final String productName;
  final String? sku;
  final int onHand;
  final int? lowStockLevel;
  final int unitCostPaisa;
  final int valuationPaisa;

  const StockLevel({
    required this.productId,
    required this.productName,
    this.sku,
    required this.onHand,
    this.lowStockLevel,
    this.unitCostPaisa = 0,
    this.valuationPaisa = 0,
  });

  bool get isLowStock => lowStockLevel != null && onHand <= lowStockLevel!;

  factory StockLevel.fromJson(Map<String, dynamic> json) {
    final prod = json['product'] is Map ? json['product'] as Map : const {};
    final onHand = Extractor.asInt(json['on_hand'] ?? json['quantity']);
    final cost = Extractor.asInt(json['unit_cost_paisa'] ?? prod['cost_price_paisa']);
    return StockLevel(
      productId: json['product_id']?.toString() ?? prod['id']?.toString() ?? json['id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? prod['name']?.toString() ?? json['name']?.toString() ?? 'Product',
      sku: json['sku']?.toString() ?? prod['sku']?.toString(),
      onHand: onHand,
      lowStockLevel: Extractor.asNullableInt(json['low_stock_level'] ?? prod['low_stock_level']),
      unitCostPaisa: cost,
      valuationPaisa: Extractor.asInt(json['valuation_paisa'], onHand * cost),
    );
  }
}

class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final int quantityChange;
  final String type; // 'adjustment' | 'sale' | 'return' | 'stocktake'
  final String? reason;
  final DateTime? createdAt;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantityChange,
    required this.type,
    this.reason,
    this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    final prod = json['product'] is Map ? json['product'] as Map : const {};
    DateTime? dt;
    if (json['created_at'] != null) {
      try {
        dt = DateTime.parse(json['created_at'].toString()).toLocal();
      } catch (_) {}
    }
    return StockMovement(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? prod['id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? prod['name']?.toString() ?? 'Product',
      quantityChange: Extractor.asInt(json['quantity_change']),
      type: json['type']?.toString() ?? 'adjustment',
      reason: json['reason']?.toString() ?? json['note']?.toString(),
      createdAt: dt,
    );
  }
}
