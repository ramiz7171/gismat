import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// FCM + local notifications. Fully optional: if Firebase isn't configured
/// (no google-services.json / GoogleService-Info.plist, or web/CI), every
/// call is a silent no-op and the app works normally.
abstract final class PushService {
  static bool _available = false;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'gismat_default',
    'GISMAT',
    description: 'Pokes, matches and messages',
    importance: Importance.high,
  );

  static Future<void> tryInitialize() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      _available = true;
    } catch (_) {
      _available = false;
      return;
    }
    try {
      await _local.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ));
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
    } catch (_) {
      // never block startup on push plumbing
    }
  }

  /// Request permission + register the device token. Call after sign-in.
  static Future<void> registerDevice() async {
    if (!_available) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      final user = Supabase.instance.client.auth.currentUser;
      if (token == null || user == null) return;
      await Supabase.instance.client.from('devices').upsert({
        'user_id': user.id,
        'fcm_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      messaging.onTokenRefresh.listen((t) async {
        await Supabase.instance.client.from('devices').upsert({
          'user_id': user.id,
          'fcm_token': t,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      });
    } catch (_) {
      // best-effort
    }
  }

  static Future<void> unregisterDevice() async {
    if (!_available) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      final user = Supabase.instance.client.auth.currentUser;
      if (token == null || user == null) return;
      await Supabase.instance.client
          .from('devices')
          .delete()
          .match({'user_id': user.id, 'fcm_token': token});
    } catch (_) {}
  }

  static Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(_channel.id, _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // System tray handles display for data+notification payloads; nothing to do.
}
