// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Minimal test: generate a tiny password-protected PDF from scratch
/// (no `pdf` package) so we can verify the encryption algorithm in isolation.
///
/// Run with: dart test/pdf_encryption_test.dart
void main() {
  const password = '123456';
  final fileId = utf8.encode('test-file-id-1234'); // Fixed 18-byte ID

  final enc = PdfStdEncrypt(password: password, fileId: fileId);

  // ---- build a minimal PDF manually ----
  final buf = StringBuffer();
  buf.write('%PDF-1.4\n');

  // obj 1 – Catalog
  buf.write('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

  // obj 2 – Pages
  buf.write('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');

  // obj 3 – Page
  buf.write(
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >>\nendobj\n');

  // obj 4 – Encrypt dictionary
  final oHex = _hex(enc.ownerKey);
  final uHex = _hex(enc.userKey);
  buf.write('4 0 obj\n');
  buf.write('<< /Filter /Standard /V 1 /R 2 /P -4 /Length 40\n');
  buf.write('   /O <$oHex>\n');
  buf.write('   /U <$uHex>\n');
  buf.write('>>\nendobj\n');

  // xref
  final body = buf.toString();
  // Find object offsets
  final off1 = body.indexOf('1 0 obj');
  final off2 = body.indexOf('2 0 obj');
  final off3 = body.indexOf('3 0 obj');
  final off4 = body.indexOf('4 0 obj');
  final xrefOffset = body.length;

  buf.write('xref\n');
  buf.write('0 5\n');
  buf.write('0000000000 65535 f \n');
  buf.write('${off1.toString().padLeft(10, '0')} 00000 n \n');
  buf.write('${off2.toString().padLeft(10, '0')} 00000 n \n');
  buf.write('${off3.toString().padLeft(10, '0')} 00000 n \n');
  buf.write('${off4.toString().padLeft(10, '0')} 00000 n \n');

  // trailer
  final idHex = _hex(fileId);
  buf.write('trailer\n');
  buf.write(
      '<< /Size 5 /Root 1 0 R /Encrypt 4 0 R /ID [<$idHex> <$idHex>] >>\n');
  buf.write('startxref\n$xrefOffset\n%%EOF\n');

  final outPath = '/tmp/test_encrypted.pdf';
  File(outPath).writeAsStringSync(buf.toString());
  print('Written to $outPath');
  print('Password: $password');
  print('O = $oHex');
  print('U = $uHex');
  print('ID = $idHex');
  print('\nTry: open $outPath and enter password "$password"');
}

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

class PdfStdEncrypt {
  PdfStdEncrypt({required String password, required List<int> fileId}) {
    _userPwd = _padPassword(password);
    _ownerPwd = _padPassword(password);
    _fileId = Uint8List.fromList(fileId);
    _computeKeys();
  }

  static const _padding = <int>[
    0x28, 0xBF, 0x4E, 0x5E, 0x4E, 0x75, 0x8A, 0x41,
    0x64, 0x00, 0x4E, 0x56, 0xFF, 0xFA, 0x01, 0x08,
    0x2E, 0x2E, 0x00, 0xB6, 0xD0, 0x68, 0x3E, 0x80,
    0x2F, 0x0C, 0xA9, 0xFE, 0x64, 0x53, 0x69, 0x7A,
  ];

  static const _permissions = -4;

  late final Uint8List _userPwd;
  late final Uint8List _ownerPwd;
  late final Uint8List _fileId;
  late final Uint8List _ownerKey;
  late final Uint8List _userKey;
  late final Uint8List _encryptionKey;

  List<int> get ownerKey => _ownerKey;
  List<int> get userKey => _userKey;

  Uint8List _padPassword(String password) {
    final bytes =
        latin1.encode(password.length > 32 ? password.substring(0, 32) : password);
    final padded = Uint8List(32);
    padded.setRange(0, bytes.length, bytes);
    padded.setRange(bytes.length, 32, _padding);
    return padded;
  }

  Uint8List _rc4(Uint8List key, Uint8List data) {
    final s = List<int>.generate(256, (i) => i);
    var j = 0;
    for (var i = 0; i < 256; i++) {
      j = (j + s[i] + key[i % key.length]) & 0xFF;
      final t = s[i];
      s[i] = s[j];
      s[j] = t;
    }
    final out = Uint8List(data.length);
    var x = 0;
    var y = 0;
    for (var i = 0; i < data.length; i++) {
      x = (x + 1) & 0xFF;
      y = (y + s[x]) & 0xFF;
      final t = s[x];
      s[x] = s[y];
      s[y] = t;
      out[i] = data[i] ^ s[(s[x] + s[y]) & 0xFF];
    }
    return out;
  }

  void _computeKeys() {
    // Algorithm 3.3: O value
    final oHash = md5.convert(_ownerPwd).bytes;
    final oKey = Uint8List.fromList(oHash.sublist(0, 5));
    _ownerKey = _rc4(oKey, _userPwd);

    // Algorithm 3.2: encryption key
    final keyInput = <int>[
      ..._userPwd,
      ..._ownerKey,
      _permissions & 0xFF,
      (_permissions >> 8) & 0xFF,
      (_permissions >> 16) & 0xFF,
      (_permissions >> 24) & 0xFF,
      ..._fileId,
    ];
    final keyHash = md5.convert(keyInput).bytes;
    _encryptionKey = Uint8List.fromList(keyHash.sublist(0, 5));

    // Algorithm 3.4: U value
    _userKey = _rc4(_encryptionKey, Uint8List.fromList(_padding));
  }
}