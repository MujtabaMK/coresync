enum RecipeCategory {
  breakfast('Breakfast'),
  lunch('Lunch'),
  dinner('Dinner'),
  snack('Snacks'),
  salad('Salads'),
  soup('Soups'),
  smoothie('Smoothies'),
  healthyDessert('Healthy Desserts');

  const RecipeCategory(this.label);
  final String label;
}

class RecipeModel {
  const RecipeModel({
    this.id = '',
    required this.name,
    required this.category,
    required this.ingredients,
    required this.preparation,
    required this.servingSize,
    this.servings = 1,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.isVegetarian = false,
    this.notes,
    this.videoUrl,
  });

  final String id;
  final String name;
  final RecipeCategory category;
  final List<String> ingredients;
  final List<String> preparation;
  final String servingSize;
  final int servings;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final bool isVegetarian;
  final String? notes;
  final String? videoUrl;

  static String generateVideoUrl(String name) {
    final query = Uri.encodeComponent('$name recipe');
    return 'https://www.youtube.com/results?search_query=$query';
  }

  factory RecipeModel.fromFirestore(String id, Map<String, dynamic> data) {
    return RecipeModel(
      id: id,
      name: data['name'] as String? ?? '',
      category: RecipeCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => RecipeCategory.breakfast,
      ),
      ingredients: List<String>.from(data['ingredients'] ?? []),
      preparation: List<String>.from(data['preparation'] ?? []),
      servingSize: data['servingSize'] as String? ?? '',
      servings: data['servings'] as int? ?? 1,
      calories: data['calories'] as int? ?? 0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0,
      isVegetarian: data['isVegetarian'] as bool? ?? false,
      notes: data['notes'] as String?,
      videoUrl: data['videoUrl'] as String?,
    );
  }

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return RecipeModel(
      name: name,
      category: RecipeCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => RecipeCategory.breakfast,
      ),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      preparation: List<String>.from(json['preparation'] ?? []),
      servingSize: json['servingSize'] as String? ?? '',
      servings: json['servings'] as int? ?? 1,
      calories: json['calories'] as int? ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      isVegetarian: json['isVegetarian'] as bool? ?? false,
      notes: json['notes'] as String?,
      videoUrl: json['videoUrl'] as String? ?? generateVideoUrl(name),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category.name,
      'ingredients': ingredients,
      'preparation': preparation,
      'servingSize': servingSize,
      'servings': servings,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'isVegetarian': isVegetarian,
      'notes': notes,
      'videoUrl': videoUrl,
    };
  }
}
