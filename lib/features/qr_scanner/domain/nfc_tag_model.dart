class NfcTagModel {
  final String id;
  final String? payload;
  final String techType;
  final DateTime readAt;

  const NfcTagModel({
    required this.id,
    this.payload,
    required this.techType,
    required this.readAt,
  });
}
