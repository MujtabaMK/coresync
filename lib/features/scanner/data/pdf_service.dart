import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/format/num.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/format/object_base.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/format/string.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  PdfService._();

  /// Generates a PDF from the given image paths and saves it to [outputPath].
  static Future<File> generatePdf({
    required List<String> imagePaths,
    required String outputPath,
  }) async {
    final pdf = pw.Document();

    for (final path in imagePaths) {
      final imageFile = File(path);
      final imageBytes = await imageFile.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    final file = File(outputPath);
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Generates a password-protected PDF using standard RC4 40-bit encryption.
  static Future<File> generateProtectedPdf({
    required List<String> imagePaths,
    required String outputPath,
    required String password,
  }) async {
    // Use PDF 1.4 with no compression for maximum compatibility with
    // V=1/R=2 encryption. PDF 1.5+ uses compressed xref streams which
    // can cause "invalid password" errors in some readers.
    final pdf = pw.Document(
      version: PdfVersion.pdf_1_4,
      compress: false,
    );

    for (final path in imagePaths) {
      final imageFile = File(path);
      final imageBytes = await imageFile.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    // Set real PDF encryption on the underlying document
    pdf.document.encryption = _PdfStandardEncryption(
      pdf.document,
      userPassword: password,
      ownerPassword: password,
    );

    final file = File(outputPath);
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Generates a compressed PDF by first compressing images.
  static Future<File> generateCompressedPdf({
    required List<String> imagePaths,
    required String outputPath,
    int quality = 50,
  }) async {
    final pdf = pw.Document();

    for (final path in imagePaths) {
      final imageFile = File(path);
      final imageBytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) continue;

      final compressed = img.encodeJpg(decoded, quality: quality);
      final image = pw.MemoryImage(compressed);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    final file = File(outputPath);
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);
    return file;
  }
}

/// Standard PDF encryption (RC4 40-bit, PDF 1.4 compatible).
/// Implements the algorithm described in the PDF Reference section 3.5.
class _PdfStandardEncryption extends PdfEncryption {
  _PdfStandardEncryption(
    super.pdfDocument, {
    required String userPassword,
    required String ownerPassword,
  }) {
    _userPwd = _padPassword(userPassword);
    _ownerPwd = _padPassword(ownerPassword);
    _fileId = pdfDocument.documentID;
    _computeKeys();
  }

  /// Standard 32-byte padding defined in the PDF spec (Table 3.19).
  static const _padding = <int>[
    0x28, 0xBF, 0x4E, 0x5E, 0x4E, 0x75, 0x8A, 0x41,
    0x64, 0x00, 0x4E, 0x56, 0xFF, 0xFA, 0x01, 0x08,
    0x2E, 0x2E, 0x00, 0xB6, 0xD0, 0x68, 0x3E, 0x80,
    0x2F, 0x0C, 0xA9, 0xFE, 0x64, 0x53, 0x69, 0x7A,
  ];

  // Allow printing and copying
  static const _permissions = -4; // 0xFFFFFFFC

  late final Uint8List _userPwd;
  late final Uint8List _ownerPwd;
  late final Uint8List _fileId;
  late final Uint8List _ownerKey;
  late final Uint8List _userKey;
  late final Uint8List _encryptionKey;

  /// Pad or truncate password to exactly 32 bytes using standard padding.
  Uint8List _padPassword(String password) {
    final bytes = latin1.encode(
      password.length > 32 ? password.substring(0, 32) : password,
    );
    final padded = Uint8List(32);
    padded.setRange(0, bytes.length, bytes);
    padded.setRange(bytes.length, 32, _padding);
    return padded;
  }

  /// RC4 encrypt/decrypt.
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

  /// Compute O value, U value, and encryption key per PDF spec Algorithm 3.2-3.5.
  void _computeKeys() {
    // --- Algorithm 3.3: Compute O value ---
    final oHash = md5.convert(_ownerPwd).bytes;
    final oKey = Uint8List.fromList(oHash.sublist(0, 5));
    _ownerKey = _rc4(oKey, _userPwd);

    // --- Algorithm 3.2: Compute encryption key ---
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

    // --- Algorithm 3.4: Compute U value ---
    _userKey = _rc4(_encryptionKey, Uint8List.fromList(_padding));

    // --- Write the encryption dictionary ---
    params['/Filter'] = const PdfName('/Standard');
    params['/V'] = const PdfNum(1);
    params['/R'] = const PdfNum(2);
    params['/P'] = PdfNum(_permissions);
    params['/O'] = PdfString(
      _ownerKey,
      format: PdfStringFormat.binary,
      encrypted: false,
    );
    params['/U'] = PdfString(
      _userKey,
      format: PdfStringFormat.binary,
      encrypted: false,
    );
    params['/Length'] = const PdfNum(40);
  }

  @override
  Uint8List encrypt(Uint8List input, PdfObjectBase object) {
    // --- Algorithm 3.1: Encrypt data using object-specific key ---
    final objKey = md5.convert(<int>[
      ..._encryptionKey,
      object.objser & 0xFF,
      (object.objser >> 8) & 0xFF,
      (object.objser >> 16) & 0xFF,
      object.objgen & 0xFF,
      (object.objgen >> 8) & 0xFF,
    ]).bytes;

    final keyLen = min(16, _encryptionKey.length + 5);
    return _rc4(Uint8List.fromList(objKey.sublist(0, keyLen)), input);
  }
}
