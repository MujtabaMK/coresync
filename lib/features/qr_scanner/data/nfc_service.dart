import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';

import '../domain/nfc_tag_model.dart';

class NfcService {
  /// Check if NFC is available on the device.
  Future<bool> isAvailable() => NfcManager.instance.isAvailable();

  /// Start a single NFC tag read session.
  /// Returns the first tag read, then stops the session.
  Future<NfcTagModel> readTag() async {
    NfcTagModel? result;
    Object? error;

    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          result = _parseTag(tag);
        } catch (e) {
          error = e;
        } finally {
          await NfcManager.instance.stopSession();
        }
      },
      onError: (e) async {
        error = e;
        await NfcManager.instance.stopSession();
      },
    );

    // Wait briefly for the callback
    // In practice the caller should use a stream / completer
    // but for simplicity we return a future-based approach.
    await Future.delayed(const Duration(milliseconds: 100));

    if (error != null) throw error!;
    if (result != null) return result!;
    throw Exception('No NFC tag detected');
  }

  /// Start continuous NFC reading. Results delivered via [onTag].
  void startSession({
    required void Function(NfcTagModel tag) onTag,
    required void Function(Object error) onError,
  }) {
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          onTag(_parseTag(tag));
        } catch (e) {
          onError(e);
        }
      },
      onError: (e) async => onError(e),
    );
  }

  Future<void> stopSession() async {
    await NfcManager.instance.stopSession();
  }

  NfcTagModel _parseTag(NfcTag tag) {
    String? payload;
    String techType = 'Unknown';

    final ndef = Ndef.from(tag);
    if (ndef != null && ndef.cachedMessage != null) {
      final records = ndef.cachedMessage!.records;
      if (records.isNotEmpty) {
        payload = _decodeNdefPayload(records.first);
      }
      techType = 'NDEF';
    } else {
      // Try NfcA, NfcB, etc.
      final data = tag.data;
      if (data.containsKey('nfca')) {
        techType = 'NfcA';
      } else if (data.containsKey('nfcb')) {
        techType = 'NfcB';
      } else if (data.containsKey('nfcf')) {
        techType = 'NfcF';
      } else if (data.containsKey('nfcv')) {
        techType = 'NfcV';
      } else if (data.containsKey('isodep')) {
        techType = 'IsoDep';
      }
    }

    final id = tag.data.values
        .whereType<Map>()
        .expand((m) => [if (m.containsKey('identifier')) m['identifier']])
        .whereType<Uint8List>()
        .map((b) => b.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':'))
        .firstOrNull ?? 'unknown';

    return NfcTagModel(
      id: id,
      payload: payload,
      techType: techType,
      readAt: DateTime.now(),
    );
  }

  String? _decodeNdefPayload(NdefRecord record) {
    if (record.payload.isEmpty) return null;
    // Text record (TNF=1, type='T')
    if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
        record.type.isNotEmpty &&
        record.type.first == 0x54) {
      final langCodeLen = record.payload.first;
      return String.fromCharCodes(record.payload.sublist(1 + langCodeLen));
    }
    // URI record (TNF=1, type='U')
    if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
        record.type.isNotEmpty &&
        record.type.first == 0x55) {
      const prefixes = [
        '', 'http://www.', 'https://www.', 'http://', 'https://',
        'tel:', 'mailto:', 'ftp://anonymous:anonymous@', 'ftp://ftp.',
        'ftps://', 'sftp://', 'smb://', 'nfs://', 'ftp://', 'dav://',
        'news:', 'telnet://', 'imap:', 'rtsp://', 'urn:',
        'pop:', 'sip:', 'sips:', 'tftp:', 'btspp://', 'btl2cap://',
        'btgoep://', 'tcpobex://', 'irdaobex://', 'file://',
        'urn:epc:id:', 'urn:epc:tag:', 'urn:epc:pat:', 'urn:epc:raw:',
        'urn:epc:', 'urn:nfc:',
      ];
      final prefixIndex = record.payload.first;
      final prefix = prefixIndex < prefixes.length ? prefixes[prefixIndex] : '';
      return prefix + String.fromCharCodes(record.payload.sublist(1));
    }
    return String.fromCharCodes(record.payload);
  }
}
