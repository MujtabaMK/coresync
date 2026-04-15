class CommonFoodItem {
  const CommonFoodItem({
    required this.name,
    required this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sodium = 0,
    this.sugar = 0,
    this.cholesterol = 0,
    this.iron = 0,
    this.calcium = 0,
    this.potassium = 0,
    this.vitaminA = 0,
    this.vitaminB12 = 0,
    this.vitaminC = 0,
    this.vitaminD = 0,
    this.zinc = 0,
    this.magnesium = 0,
    this.vitaminE = 0,
    this.vitaminK = 0,
    this.vitaminB6 = 0,
    this.folate = 0,
    this.phosphorus = 0,
    this.selenium = 0,
    this.manganese = 0,
    this.category = '',
  });

  final String name;
  final String servingSize;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium; // mg
  final double sugar; // g
  final double cholesterol; // mg
  final double iron; // mg
  final double calcium; // mg
  final double potassium; // mg
  final double vitaminA; // mcg RAE
  final double vitaminB12; // mcg
  final double vitaminC; // mg
  final double vitaminD; // mcg
  final double zinc; // mg
  final double magnesium; // mg
  final double vitaminE; // mg
  final double vitaminK; // mcg
  final double vitaminB6; // mg
  final double folate; // mcg DFE
  final double phosphorus; // mg
  final double selenium; // mcg
  final double manganese; // mg
  final String category;

  factory CommonFoodItem.fromJson(Map<String, dynamic> j) => CommonFoodItem(
        name: j['name'] as String,
        servingSize: j['servingSize'] as String,
        calories: (j['calories'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
        fiber: (j['fiber'] as num? ?? 0).toDouble(),
        sodium: (j['sodium'] as num? ?? 0).toDouble(),
        sugar: (j['sugar'] as num? ?? 0).toDouble(),
        cholesterol: (j['cholesterol'] as num? ?? 0).toDouble(),
        iron: (j['iron'] as num? ?? 0).toDouble(),
        calcium: (j['calcium'] as num? ?? 0).toDouble(),
        potassium: (j['potassium'] as num? ?? 0).toDouble(),
        vitaminA: (j['vitaminA'] as num? ?? 0).toDouble(),
        vitaminB12: (j['vitaminB12'] as num? ?? 0).toDouble(),
        vitaminC: (j['vitaminC'] as num? ?? 0).toDouble(),
        vitaminD: (j['vitaminD'] as num? ?? 0).toDouble(),
        zinc: (j['zinc'] as num? ?? 0).toDouble(),
        magnesium: (j['magnesium'] as num? ?? 0).toDouble(),
        vitaminE: (j['vitaminE'] as num? ?? 0).toDouble(),
        vitaminK: (j['vitaminK'] as num? ?? 0).toDouble(),
        vitaminB6: (j['vitaminB6'] as num? ?? 0).toDouble(),
        folate: (j['folate'] as num? ?? 0).toDouble(),
        phosphorus: (j['phosphorus'] as num? ?? 0).toDouble(),
        selenium: (j['selenium'] as num? ?? 0).toDouble(),
        manganese: (j['manganese'] as num? ?? 0).toDouble(),
        category: j['category'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'servingSize': servingSize,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sodium': sodium,
        'sugar': sugar,
        'cholesterol': cholesterol,
        'iron': iron,
        'calcium': calcium,
        'potassium': potassium,
        'vitaminA': vitaminA,
        'vitaminB12': vitaminB12,
        'vitaminC': vitaminC,
        'vitaminD': vitaminD,
        'zinc': zinc,
        'magnesium': magnesium,
        'vitaminE': vitaminE,
        'vitaminK': vitaminK,
        'vitaminB6': vitaminB6,
        'folate': folate,
        'phosphorus': phosphorus,
        'selenium': selenium,
        'manganese': manganese,
        'category': category,
      };
}
