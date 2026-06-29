class MarketingCodingItem {
  final String name;
  final String code;

  const MarketingCodingItem({
    required this.name,
    required this.code,
  });

  factory MarketingCodingItem.fromMap(Map<String, dynamic> map) {
    return MarketingCodingItem(
      name: (map['name'] as String?)?.trim() ?? '',
      code: (map['code'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'code': code,
      };
}

class MarketingCodingMetric {
  final int count;
  final List<MarketingCodingItem> items;

  const MarketingCodingMetric({
    required this.count,
    required this.items,
  });

  static const empty = MarketingCodingMetric(count: 0, items: []);

  factory MarketingCodingMetric.fromMap(Map<String, dynamic>? map) {
    if (map == null) return MarketingCodingMetric.empty;

    final rawItems = map['items'];
    if (rawItems is List && rawItems.isNotEmpty) {
      final items = rawItems
          .whereType<Map>()
          .map((e) => MarketingCodingItem.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.name.isNotEmpty)
          .toList();
      return MarketingCodingMetric(count: items.length, items: items);
    }

    // Backward compatibility with older records that only stored names.
    final rawNames = map['names'];
    final names = rawNames is List
        ? rawNames
            .map((e) => (e as String?)?.trim() ?? '')
            .where((n) => n.isNotEmpty)
            .toList()
        : <String>[];
    final items = names
        .map((name) => MarketingCodingItem(name: name, code: ''))
        .toList();
    final count = (map['count'] as num?)?.toInt() ?? items.length;
    return MarketingCodingMetric(count: count, items: items);
  }

  Map<String, dynamic> toMap() => {
        'count': count,
        'items': items.map((e) => e.toMap()).toList(),
      };
}
