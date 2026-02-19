// lib/models/subscription.dart

class Subscription {
  final int id;
  final String name;
  final double price;
  final int duration; // В днях
  final String features;
  final bool isActive;
  final bool renewable;

  Subscription({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.features,
    required this.isActive,
    this.renewable = false,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      duration: json['duration'],
      features: json['features'],
      isActive: json['is_active'],
      renewable: json['renewable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'duration': duration,
      'features': features,
      'is_active': isActive,
      'renewable': renewable,
    };
  }
}
