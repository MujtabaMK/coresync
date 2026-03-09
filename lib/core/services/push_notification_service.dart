import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'fcm_sender.dart';
import 'notification_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static StreamSubscription<QuerySnapshot>? _notificationSub;
  static String? _listeningUid;
  static final Set<String> _shownNotificationIds = {};

  static const _uuid = Uuid();

  static Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    _messaging.onTokenRefresh.listen(_saveToken);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  static Future<void> saveTokenForUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(token);
    } catch (e) {
      debugPrint('FCM token save failed: $e');
    }
  }

  static Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // Extract notifKey from data payload for deduplication
    final notifKey = message.data['notifKey'] as String?;
    if (notifKey != null) {
      if (_shownNotificationIds.contains(notifKey)) return;
      _shownNotificationIds.add(notifKey);
    }

    final notification = message.notification;
    if (notification != null) {
      NotificationService.showInstantNotification(
        id: notification.hashCode,
        title: notification.title ?? 'CoreSync',
        body: notification.body ?? '',
        channelId: 'shared_tasks',
        channelName: 'Shared Tasks',
      );
    }
  }

  /// Listen for notifications targeting the current user.
  /// Uses only a single where clause — no composite index needed.
  static void listenForNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_listeningUid == user.uid && _notificationSub != null) return;

    _notificationSub?.cancel();
    _listeningUid = user.uid;
    _shownNotificationIds.clear();

    debugPrint('Starting notification listener for uid: ${user.uid}');

    _notificationSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('targetUid', isEqualTo: user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final doc = change.doc;
            final data = doc.data();
            if (data == null) continue;

            final isRead = data['read'] as bool? ?? false;
            if (isRead) continue;

            // Deduplicate: skip if FCM already showed this notification
            final notifKey = data['notifKey'] as String?;
            if (notifKey != null && _shownNotificationIds.contains(notifKey)) {
              // Already shown via FCM foreground handler — just mark read
              doc.reference.update({'read': true}).catchError((e) {
                debugPrint('Failed to mark notification read: $e');
              });
              continue;
            }

            if (_shownNotificationIds.contains(doc.id)) continue;
            _shownNotificationIds.add(doc.id);
            if (notifKey != null) _shownNotificationIds.add(notifKey);

            debugPrint('New notification: ${data['title']}');

            NotificationService.showInstantNotification(
              id: doc.id.hashCode,
              title: data['title'] as String? ?? 'CoreSync',
              body: data['body'] as String? ?? '',
              channelId: 'shared_tasks',
              channelName: 'Shared Tasks',
            );

            doc.reference.update({'read': true}).catchError((e) {
              debugPrint('Failed to mark notification read: $e');
            });
          }
        }
      },
      onError: (e) {
        debugPrint('Notification listener error: $e');
        _notificationSub?.cancel();
        _notificationSub = null;
        _listeningUid = null;
        // Retry after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          debugPrint('Retrying notification listener...');
          listenForNotifications();
        });
      },
    );
  }

  /// Send a notification to another user.
  static Future<void> sendNotification({
    required String targetUid,
    required String title,
    required String body,
  }) async {
    debugPrint('Sending notification to $targetUid: $title');

    final notifKey = _uuid.v4();

    // Look up the target user's FCM token
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .get();
    final fcmToken = userDoc.data()?['fcmToken'] as String?;

    // Send push notification via FCM v1 API
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await FcmSender.send(
        fcmToken: fcmToken,
        title: title,
        body: body,
        targetUid: targetUid,
        data: {'notifKey': notifKey},
      );
    }

    // Create Firestore notification doc (in-app history)
    await FirebaseFirestore.instance.collection('notifications').add({
      'targetUid': targetUid,
      'title': title,
      'body': body,
      'read': false,
      'notifKey': notifKey,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('Notification sent successfully');
  }

  static void dispose() {
    _notificationSub?.cancel();
    _notificationSub = null;
    _listeningUid = null;
    _shownNotificationIds.clear();
    FcmSender.dispose();
  }
}
