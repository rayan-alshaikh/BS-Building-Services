class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.isActive,
  });

  /// Firestore document id
  final String id;

  /// Provider uid
  final String providerId;

  /// Service title
  final String title;

  /// Short description
  final String description;

  /// Approx. price
  final double price;

  /// Service category (plumbing, electrical, etc.)
  final String category;

  /// Is service enabled
  final bool isActive;

  factory ServiceModel.fromMap(Map<String, dynamic> map, String documentId) {
    final dynamic priceRaw = map['price'];

    final double safePrice = switch (priceRaw) {
      num v => v.toDouble(),
      String v => double.tryParse(v) ?? 0.0,
      _ => 0.0,
    };

    return ServiceModel(
      id: documentId,
      providerId: (map['providerId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      price: safePrice,
      category: (map['category'] as String?) ?? '',
      isActive: (map['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'isActive': isActive,
    };
  }
}
