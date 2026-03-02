import 'package:hive/hive.dart';

part 'password_entry_model.g.dart';

@HiveType(typeId: 0)
class PasswordEntryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String passwordFor;

  @HiveField(2)
  final String username;

  @HiveField(3)
  final String password;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  PasswordEntryModel({
    required this.id,
    required this.passwordFor,
    required this.username,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  PasswordEntryModel copyWith({
    String? id,
    String? passwordFor,
    String? username,
    String? password,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PasswordEntryModel(
      id: id ?? this.id,
      passwordFor: passwordFor ?? this.passwordFor,
      username: username ?? this.username,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
