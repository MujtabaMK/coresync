import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/hive_service.dart';
import '../domain/password_entry_model.dart';

class PasswordRepository {
  Box<PasswordEntryModel>? _box;

  Future<Box<PasswordEntryModel>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await HiveService.openEncryptedBox<PasswordEntryModel>(
      AppConstants.passwordsBox,
    );
    return _box!;
  }

  Future<List<PasswordEntryModel>> getAllPasswords() async {
    final box = await _getBox();
    final passwords = box.values.toList();
    passwords.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return passwords;
  }

  Future<PasswordEntryModel?> getPasswordById(String id) async {
    final box = await _getBox();
    try {
      return box.values.firstWhere((entry) => entry.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addPassword(PasswordEntryModel entry) async {
    final box = await _getBox();
    await box.put(entry.id, entry);
  }

  Future<void> updatePassword(PasswordEntryModel entry) async {
    final box = await _getBox();
    await box.put(entry.id, entry);
  }

  Future<void> deletePassword(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<List<PasswordEntryModel>> searchPasswords(String query) async {
    final box = await _getBox();
    final lowerQuery = query.toLowerCase();
    final passwords = box.values.where((entry) {
      return entry.passwordFor.toLowerCase().contains(lowerQuery) ||
          entry.username.toLowerCase().contains(lowerQuery);
    }).toList();
    passwords.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return passwords;
  }
}
