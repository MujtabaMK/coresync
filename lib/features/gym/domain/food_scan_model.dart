class FoodItem {
  FoodItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.quantity = 1,
  });

  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int quantity;

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] as String? ?? 'Unknown',
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'quantity': quantity,
      };

  FoodItem copyWith({
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    int? quantity,
  }) {
    return FoodItem(
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      quantity: quantity ?? this.quantity,
    );
  }
}

class FoodScanModel {
  FoodScanModel({
    required this.id,
    required this.foodItems,
    required this.totalCalories,
    this.imageUrl,
    DateTime? scannedAt,
  }) : scannedAt = scannedAt ?? DateTime.now();

  final String id;
  final List<FoodItem> foodItems;
  final double totalCalories;
  final String? imageUrl;
  final DateTime scannedAt;

  factory FoodScanModel.fromFirestore(String id, Map<String, dynamic> data) {
    final items = (data['foodItems'] as List<dynamic>?)
            ?.map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return FoodScanModel(
      id: id,
      foodItems: items,
      totalCalories: (data['totalCalories'] as num?)?.toDouble() ?? 0,
      imageUrl: data['imageUrl'] as String?,
      scannedAt: data['scannedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['scannedAt'] as num).toInt())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'foodItems': foodItems.map((e) => e.toJson()).toList(),
        'totalCalories': totalCalories,
        'imageUrl': imageUrl,
        'scannedAt': scannedAt.millisecondsSinceEpoch,
      };
}
