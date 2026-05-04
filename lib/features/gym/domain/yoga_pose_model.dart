class YogaPose {
  final int id;
  final String englishName;
  final String sanskritNameAdapted;
  final String sanskritName;
  final String translationName;
  final String description;
  final String benefits;
  final String difficulty;
  final String pngUrl;

  const YogaPose({
    required this.id,
    required this.englishName,
    required this.sanskritNameAdapted,
    required this.sanskritName,
    required this.translationName,
    required this.description,
    required this.benefits,
    required this.difficulty,
    required this.pngUrl,
  });

  factory YogaPose.fromJson(Map<String, dynamic> json) {
    return YogaPose(
      id: json['id'] as int,
      englishName: json['english_name'] as String? ?? '',
      sanskritNameAdapted: json['sanskrit_name_adapted'] as String? ?? '',
      sanskritName: json['sanskrit_name'] as String? ?? '',
      translationName: json['translation_name'] as String? ?? '',
      description: json['pose_description'] as String? ?? '',
      benefits: json['pose_benefits'] as String? ?? '',
      difficulty: json['difficulty_level'] as String? ?? '',
      pngUrl: json['url_png'] as String? ?? '',
    );
  }
}
