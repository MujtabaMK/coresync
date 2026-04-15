import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FcmSender {
  FcmSender._();

  static const _projectId = 'coresync-e7fb5';
  static const _fcmScope = 'https://www.googleapis.com/auth/firebase.messaging';
  static const _fcmUrl =
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

  static AutoRefreshingAuthClient? _client;

  static Future<AutoRefreshingAuthClient> _getClient() async {
    if (_client != null) return _client!;

    final jsonStr =
        await rootBundle.loadString('assets/service-account.json');
    final credentials = ServiceAccountCredentials.fromJson(jsonStr);
    _client = await clientViaServiceAccount(credentials, [_fcmScope]);
    return _client!;
  }

  /// Send a push notification via FCM v1 API.
  ///
  /// Returns `true` if the message was accepted by FCM.
  /// On invalid/unregistered token, removes the stale token from Firestore.
  static Future<bool> send({
    required String fcmToken,
    required String title,
    required String body,
    String? targetUid,
    Map<String, String>? data,
  }) async {
    final payload = {
      'message': {
        'token': fcmToken,
        'notification': {
          'title': title,
          'body': body,
        },
        // APNs config ensures iOS displays the notification even when the
        // app is killed/terminated.
        'apns': {
          'headers': {
            'apns-priority': '10',
            'apns-push-type': 'alert',
          },
          'payload': {
            'aps': {
              'sound': 'default',
              'mutable-content': 1,
            },
          },
        },
        if (data != null) 'data': data,
      },
    };

    try {
      final response = await _sendRequest(payload);

      if (response.statusCode == 200) {
        debugPrint('FCM send success');
        return true;
      }

      // 401 Unauthorized → token expired, clear client and retry once
      if (response.statusCode == 401) {
        debugPrint('FCM 401 – refreshing auth client and retrying');
        _clearClient();
        final retry = await _sendRequest(payload);
        if (retry.statusCode == 200) return true;
        debugPrint('FCM retry failed: ${retry.statusCode} ${retry.body}');
        return false;
      }

      // Handle invalid / unregistered FCM token
      final responseBody = response.body;
      if (response.statusCode == 404 ||
          responseBody.contains('UNREGISTERED') ||
          responseBody.contains('INVALID_ARGUMENT')) {
        debugPrint('FCM stale token detected – cleaning up');
        if (targetUid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUid)
              .update({'fcmToken': FieldValue.delete()});
        }
        return false;
      }

      debugPrint('FCM send failed: ${response.statusCode} $responseBody');
      return false;
    } catch (e) {
      debugPrint('FCM send error: $e');
      return false;
    }
  }

  static Future<http.Response> _sendRequest(Map<String, dynamic> payload) async {
    final client = await _getClient();
    return client.post(
      Uri.parse(_fcmUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }

  static void _clearClient() {
    _client?.close();
    _client = null;
  }

  static void dispose() {
    _clearClient();
  }
}
