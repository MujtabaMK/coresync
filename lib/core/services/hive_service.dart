import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

class HiveService {
  HiveService._();

  static const _secureStorage = FlutterSecureStorage();

  static Future<List<int>> _getEncryptionKey() async {
    final storedKey = await _secureStorage.read(
      key: AppConstants.encryptionKeyName,
    );
    if (storedKey != null) {
      return base64Url.decode(storedKey);
    }
    final key = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    await _secureStorage.write(
      key: AppConstants.encryptionKeyName,
      value: base64Url.encode(key),
    );
    return key;
  }

  static Future<Box<T>> openEncryptedBox<T>(String boxName) async {
    final key = await _getEncryptionKey();
    return Hive.openBox<T>(
      boxName,
      encryptionCipher: HiveAesCipher(key),
    );
  }

  static Future<Box<T>> openBox<T>(String boxName) async {
    return Hive.openBox<T>(boxName);
  }
}
