// ignore_for_file: avoid_print, implementation_imports
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/src/pdf/format/num.dart';
import 'package:pdf/src/pdf/format/object_base.dart';
import 'package:pdf/src/pdf/format/string.dart';
import 'package:pdf/widgets.dart' as pw;

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() async {
  const password = '123456';

  final pdf = pw.Document(
    version: PdfVersion.pdf_1_4,
    compress: false,
  );

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        return pw.Center(
          child: pw.Text('Hello World - Password Protected'),
        );
      },
    ),
  );

  // Capture the document ID BEFORE setting encryption
  final docIdBefore = pdf.document.documentID;
  print('Document ID before encryption: ${_hex(docIdBefore)}');

  // Set encryption
  final enc = _PdfStandardEncryption(
    pdf.document,
    userPassword: password,
    ownerPassword: password,
  );
  pdf.document.encryption = enc;

  // Capture document ID AFTER setting encryption
  final docIdAfter = pdf.document.documentID;
  print('Document ID after encryption:  ${_hex(docIdAfter)}');
  print('IDs match: ${_hex(docIdBefore) == _hex(docIdAfter)}');

  // Print encryption values
  print('\nEncryption key: ${_hex(enc.encryptionKey)}');
  print('O value: ${_hex(enc.ownerKey)}');
  print('U value: ${_hex(enc.userKey)}');
  print('File ID used: ${_hex(enc.fileId)}');

  final bytes = await pdf.save();
  final file = File('/tmp/test_pdf_package2.pdf');
  await file.writeAsBytes(bytes);
  print('\nWritten to ${file.path} (${bytes.length} bytes)');

  // Now extract the ACTUAL ID from the saved file
  // Search for /ID in the raw bytes
  final rawStr = String.fromCharCodes(bytes);

  // Find the hex string after /ID [<
  final idPattern = RegExp(r'/ID\s*\[<([0-9a-f]+)>');
  final idMatch = idPattern.firstMatch(rawStr);
  if (idMatch != null) {
    final fileIdHex = idMatch.group(1)!;
    print('\nID in saved file: $fileIdHex');
    print('ID used for encryption: ${_hex(enc.fileId)}');
    print('IDs match: ${fileIdHex == _hex(enc.fileId)}');
  } else {
    print('\nWARNING: Could not find /ID in saved file!');
    // Try to find it in binary
    final idIdx = rawStr.indexOf('/ID');
    if (idIdx >= 0) {
      print('Found /ID at offset $idIdx');
      print('Surrounding bytes: ${rawStr.substring(idIdx, min(idIdx + 200, rawStr.length))}');
    }
  }

  // Find O and U hex strings in the file
  final oPattern = RegExp(r'/O\s*<([0-9a-f]+)>');
  final oMatch = oPattern.firstMatch(rawStr);
  if (oMatch != null) {
    print('\nO in file: ${oMatch.group(1)}');
    print('O expected: ${_hex(enc.ownerKey)}');
    print('O match: ${oMatch.group(1) == _hex(enc.ownerKey)}');
  }

  final uPattern = RegExp(r'/U\s*<([0-9a-f]+)>');
  final uMatch = uPattern.firstMatch(rawStr);
  if (uMatch != null) {
    print('U in file: ${uMatch.group(1)}');
    print('U expected: ${_hex(enc.userKey)}');
    print('U match: ${uMatch.group(1) == _hex(enc.userKey)}');
  }
}

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

  static const _padding = <int>[
    0x28, 0xBF, 0x4E, 0x5E, 0x4E, 0x75, 0x8A, 0x41,
    0x64, 0x00, 0x4E, 0x56, 0xFF, 0xFA, 0x01, 0x08,
    0x2E, 0x2E, 0x00, 0xB6, 0xD0, 0x68, 0x3E, 0x80,
    0x2F, 0x0C, 0xA9, 0xFE, 0x64, 0x53, 0x69, 0x7A,
  ];

  static const _permissions = -4;

  late final Uint8List _userPwd;
  late final Uint8List _ownerPwd;
  late Uint8List _fileId;
  late Uint8List _ownerKey;
  late Uint8List _userKey;
  late Uint8List _encryptionKey;

  Uint8List get fileId => _fileId;
  Uint8List get ownerKey => _ownerKey;
  Uint8List get userKey => _userKey;
  Uint8List get encryptionKey => _encryptionKey;

  Uint8List _padPassword(String password) {
    final bytes = latin1.encode(
      password.length > 32 ? password.substring(0, 32) : password,
    );
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
    final oHash = md5.convert(_ownerPwd).bytes;
    final oKey = Uint8List.fromList(oHash.sublist(0, 5));
    _ownerKey = _rc4(oKey, _userPwd);

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

    _userKey = _rc4(_encryptionKey, Uint8List.fromList(_padding));

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