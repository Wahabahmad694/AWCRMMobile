import '../../utils/extractor.dart';

class ProductCategory {
  final String id;
  final String name;
  final String? description;

  const ProductCategory({
    required this.id,
    required this.name,
    this.description,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) => ProductCategory(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Category',
        description: json['description']?.toString(),
      );
}

class Product {
  final String id;
  final String name;
  final String type; // 'product' | 'service'
  final String? sku;
  final String? categoryId;
  final String? categoryName;
  final String? description;
  final String? unit;
  final int pricePaisa;
  final int costPricePaisa;
  final int taxRateBps;
  final bool trackStock;
  final int? lowStockLevel;
  final int stockOnHand;
  final int version;
  final bool isArchived;

  const Product({
    required this.id,
    required this.name,
    this.type = 'product',
    this.sku,
    this.categoryId,
    this.categoryName,
    this.description,
    this.unit,
    required this.pricePaisa,
    this.costPricePaisa = 0,
    this.taxRateBps = 0,
    this.trackStock = true,
    this.lowStockLevel,
    this.stockOnHand = 0,
    this.version = 1,
    this.isArchived = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] is Map ? json['category'] as Map : const {};
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Product',
      type: json['type']?.toString() ?? 'product',
      sku: json['sku']?.toString(),
      categoryId: json['category_id']?.toString() ?? cat['id']?.toString(),
      categoryName: json['category_name']?.toString() ?? cat['name']?.toString(),
      description: json['description']?.toString(),
      unit: json['unit']?.toString(),
      pricePaisa: Extractor.asInt(json['price_paisa']),
      costPricePaisa: Extractor.asInt(json['cost_price_paisa']),
      taxRateBps: Extractor.asInt(json['tax_rate_bps']),
      trackStock: Extractor.asBool(json['track_stock'], true),
      lowStockLevel: Extractor.asNullableInt(json['low_stock_level']),
      stockOnHand: Extractor.asInt(json['stock_on_hand'] ?? json['on_hand']),
      version: Extractor.asInt(json['version'], 1),
      isArchived: json['archived_at'] != null || json['is_archived'] == true,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'type': type,
        if (sku != null) 'sku': sku,
        if (categoryId != null) 'category_id': categoryId,
        if (description != null) 'description': description,
        if (unit != null) 'unit': unit,
        'price_paisa': pricePaisa,
        'cost_price_paisa': costPricePaisa,
        'tax_rate_bps': taxRateBps,
        'track_stock': trackStock,
        if (lowStockLevel != null) 'low_stock_level': lowStockLevel,
      };
}
