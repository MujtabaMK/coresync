enum MealType {
  breakfast('Breakfast', 0.25),
  morningSnack('Morning Snack', 0.10),
  lunch('Lunch', 0.30),
  eveningSnack('Evening Snack', 0.10),
  dinner('Dinner', 0.25);

  const MealType(this.label, this.calorieShare);
  final String label;
  final double calorieShare;
}

class TrackedFoodModel {
  TrackedFoodModel({
    required this.id,
    required this.name,
    required this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealType,
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
    this.quantity = 1,
    this.measure = 'Serving',
    DateTime? trackedAt,
  }) : trackedAt = trackedAt ?? DateTime.now();

  final String id;
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
  final MealType mealType;
  final double quantity;
  final String measure;
  final DateTime trackedAt;

  double get totalCalories => calories * quantity;
  double get totalProtein => protein * quantity;
  double get totalCarbs => carbs * quantity;
  double get totalFat => fat * quantity;
  double get totalFiber => fiber * quantity;
  double get totalSodium => sodium * quantity;
  double get totalSugar => sugar * quantity;
  double get totalCholesterol => cholesterol * quantity;
  double get totalIron => iron * quantity;
  double get totalCalcium => calcium * quantity;
  double get totalPotassium => potassium * quantity;
  double get totalVitaminA => vitaminA * quantity;
  double get totalVitaminB12 => vitaminB12 * quantity;
  double get totalVitaminC => vitaminC * quantity;
  double get totalVitaminD => vitaminD * quantity;
  double get totalZinc => zinc * quantity;
  double get totalMagnesium => magnesium * quantity;
  double get totalVitaminE => vitaminE * quantity;
  double get totalVitaminK => vitaminK * quantity;
  double get totalVitaminB6 => vitaminB6 * quantity;
  double get totalFolate => folate * quantity;
  double get totalPhosphorus => phosphorus * quantity;
  double get totalSelenium => selenium * quantity;
  double get totalManganese => manganese * quantity;

  String get displayQuantity =>
      quantity % 1 == 0 ? '${quantity.toInt()}' : quantity.toStringAsFixed(2);

  Map<String, dynamic> toFirestore() => {
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
        'mealType': mealType.name,
        'quantity': quantity,
        'measure': measure,
        'trackedAt': trackedAt.millisecondsSinceEpoch,
      };

  factory TrackedFoodModel.fromFirestore(
      String id, Map<String, dynamic> data) {
    return TrackedFoodModel(
      id: id,
      name: data['name'] as String? ?? '',
      servingSize: data['servingSize'] as String? ?? '',
      calories: (data['calories'] as num?)?.toDouble() ?? 0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0,
      fiber: (data['fiber'] as num?)?.toDouble() ?? 0,
      sodium: (data['sodium'] as num?)?.toDouble() ?? 0,
      sugar: (data['sugar'] as num?)?.toDouble() ?? 0,
      cholesterol: (data['cholesterol'] as num?)?.toDouble() ?? 0,
      iron: (data['iron'] as num?)?.toDouble() ?? 0,
      calcium: (data['calcium'] as num?)?.toDouble() ?? 0,
      potassium: (data['potassium'] as num?)?.toDouble() ?? 0,
      vitaminA: (data['vitaminA'] as num?)?.toDouble() ?? 0,
      vitaminB12: (data['vitaminB12'] as num?)?.toDouble() ?? 0,
      vitaminC: (data['vitaminC'] as num?)?.toDouble() ?? 0,
      vitaminD: (data['vitaminD'] as num?)?.toDouble() ?? 0,
      zinc: (data['zinc'] as num?)?.toDouble() ?? 0,
      magnesium: (data['magnesium'] as num?)?.toDouble() ?? 0,
      vitaminE: (data['vitaminE'] as num?)?.toDouble() ?? 0,
      vitaminK: (data['vitaminK'] as num?)?.toDouble() ?? 0,
      vitaminB6: (data['vitaminB6'] as num?)?.toDouble() ?? 0,
      folate: (data['folate'] as num?)?.toDouble() ?? 0,
      phosphorus: (data['phosphorus'] as num?)?.toDouble() ?? 0,
      selenium: (data['selenium'] as num?)?.toDouble() ?? 0,
      manganese: (data['manganese'] as num?)?.toDouble() ?? 0,
      mealType: MealType.values.firstWhere(
        (e) => e.name == data['mealType'],
        orElse: () => MealType.lunch,
      ),
      quantity: (data['quantity'] as num?)?.toDouble() ?? 1,
      measure: data['measure'] as String? ?? 'Serving',
      trackedAt: data['trackedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['trackedAt'] as num).toInt())
          : DateTime.now(),
    );
  }
}
