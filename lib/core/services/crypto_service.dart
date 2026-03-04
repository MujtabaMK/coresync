import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/digests/sha256.dart';

class CryptoService {
  CryptoService._();

  /// Derives a 32-byte AES-256 key from the user's Firebase UID.
  static Key deriveKey(String uid) {
    final hash = SHA256Digest().process(Uint8List.fromList(utf8.encode(uid)));
    return Key(hash);
  }

  /// Encrypts [plainText] with AES-256-CBC using a random 16-byte IV.
  /// Returns base64(IV + ciphertext).
  static String encryptField(String plainText, Key key) {
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);
    return base64.encode(combined);
  }

  /// Decrypts a base64(IV + ciphertext) string back to plain text.
  static String decryptField(String encryptedBase64, Key key) {
    final data = base64.decode(encryptedBase64);
    final iv = IV(Uint8List.fromList(data.sublist(0, 16)));
    final cipherBytes = data.sublist(16);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.decrypt(Encrypted(Uint8List.fromList(cipherBytes)), iv: iv);
  }
}
