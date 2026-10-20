import '../../utils/extractor.dart';

class PaginatedList<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int? total;
  final bool hasMore;

  const PaginatedList({
    required this.items,
    this.page = 1,
    this.limit = 20,
    this.total,
    this.hasMore = false,
  });

  factory PaginatedList.fromJson(
    dynamic json,
    T Function(Map<String, dynamic> itemJson) fromJson,
  ) {
    final list = Extractor.extractItems(json);
    final items = list.map(fromJson).toList();
    final total = Extractor.extractTotal(json);
    int page = 1;
    int limit = 20;

    if (json is Map) {
      final meta = json['meta'] is Map ? json['meta'] as Map : null;
      if (meta != null) {
        page = Extractor.asInt(meta['page'], page);
        limit = Extractor.asInt(meta['limit'], limit);
      }
    }

    final hasMore = total != null ? (page * limit < total) : items.length >= limit;

    return PaginatedList(
      items: items,
      page: page,
      limit: limit,
      total: total,
      hasMore: hasMore,
    );
  }
}
