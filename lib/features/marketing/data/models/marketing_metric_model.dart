class MarketingMetric {
  final int count;
  final List<String> names;

  const MarketingMetric({
    required this.count,
    required this.names,
  });

  static const empty = MarketingMetric(count: 0, names: []);

  factory MarketingMetric.fromMap(Map<String, dynamic>? map) {
    if (map == null) return MarketingMetric.empty;
    final rawNames = map['names'];
    final names = rawNames is List
        ? rawNames.map((e) => (e as String?)?.trim() ?? '').where((n) => n.isNotEmpty).toList()
        : <String>[];
    final count = (map['count'] as num?)?.toInt() ?? names.length;
    return MarketingMetric(count: count, names: names);
  }

  Map<String, dynamic> toMap() => {
        'count': count,
        'names': names,
      };

  MarketingMetric copyWith({int? count, List<String>? names}) {
    return MarketingMetric(
      count: count ?? this.count,
      names: names ?? this.names,
    );
  }
}
