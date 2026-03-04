import 'package:encrypt/encrypt.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/crypto_service.dart';
import '../../../core/services/hive_service.dart';
import '../domain/password_entry_model.dart';
import 'password_sync_repository.dart';

class PasswordRepository {
  final PasswordSyncRepository? _syncRepo;
  final String? _uid;

  PasswordRepository({
    PasswordSyncRepository? syncRepo,
    String? uid,
  })  : _syncRepo = syncRepo,
        _uid = uid;

  Box<PasswordEntryModel>? _box;

  Key? get _encryptionKey =>
      _uid != null ? CryptoService.deriveKey(_uid) : null;

  String get _boxName {
    if (_uid != null && _uid.isNotEmpty) {
      return '${AppConstants.passwordsBox}_$_uid';
    }
    return AppConstants.passwordsBox;
  }

  Future<Box<PasswordEntryModel>> _getBox() async {
    if (_box != null && _box!.isOpen && _box!.name == _boxName) return _box!;
    _box = await HiveService.openEncryptedBox<PasswordEntryModel>(_boxName);
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

    // Fire-and-forget push to Firestore
    _pushToCloud(entry);
  }

  Future<void> updatePassword(PasswordEntryModel entry) async {
    final box = await _getBox();
    await box.put(entry.id, entry);

    // Fire-and-forget push to Firestore
    _pushToCloud(entry);
  }

  Future<void> deletePassword(String id) async {
    final box = await _getBox();
    await box.delete(id);

    // Fire-and-forget delete from Firestore
    _deleteFromCloud(id);
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

  /// Syncs passwords from Firestore into local Hive.
  /// Remote-only → add to Hive; Local-only → push to Firestore;
  /// Both exist → keep the one with latest updatedAt.
  Future<void> syncFromCloud() async {
    final syncRepo = _syncRepo;
    final uid = _uid;
    final key = _encryptionKey;
    if (syncRepo == null || uid == null || uid.isEmpty || key == null) return;

    try {
      final remotePasswords = await syncRepo.fetchAllPasswords(uid, key);
      final box = await _getBox();
      final localMap = {for (final p in box.values) p.id: p};
      final remoteMap = {for (final p in remotePasswords) p.id: p};

      // Remote-only → add to local Hive
      for (final entry in remotePasswords) {
        if (!localMap.containsKey(entry.id)) {
          await box.put(entry.id, entry);
        }
      }

      // Local-only → push to Firestore
      for (final entry in localMap.values) {
        if (!remoteMap.containsKey(entry.id)) {
          syncRepo.pushPassword(uid, entry, key);
        }
      }

      // Both exist → keep latest updatedAt
      for (final entry in remotePasswords) {
        final local = localMap[entry.id];
        if (local != null) {
          if (entry.updatedAt.isAfter(local.updatedAt)) {
            await box.put(entry.id, entry);
          } else if (local.updatedAt.isAfter(entry.updatedAt)) {
            syncRepo.pushPassword(uid, local, key);
          }
        }
      }
    } catch (_) {
      // Sync failure is non-fatal; local Hive data remains usable
    }
  }

  void _pushToCloud(PasswordEntryModel entry) {
    final syncRepo = _syncRepo;
    final uid = _uid;
    final key = _encryptionKey;
    if (syncRepo == null || uid == null || uid.isEmpty || key == null) return;

    syncRepo.pushPassword(uid, entry, key).catchError((_) {});
  }

  void _deleteFromCloud(String id) {
    final syncRepo = _syncRepo;
    final uid = _uid;
    if (syncRepo == null || uid == null || uid.isEmpty) return;

    syncRepo.deletePassword(uid, id).catchError((_) {});
  }
}
