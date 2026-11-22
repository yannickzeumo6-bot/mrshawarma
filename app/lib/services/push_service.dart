import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Quand l'app est fermée / en arrière-plan, Android affiche lui-même la
  // notification FCM : rien à faire ici.
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

/// Notifications push (Firebase). Si Firebase n'est pas configuré,
/// `enabled` reste false et l'app continue de fonctionner (notifications locales).
class PushService {
  PushService._();
  static final instance = PushService._();

  bool enabled = false;
  String? _token;
  bool _refreshHooked = false;
  final _fg = StreamController<RemoteMessage>.broadcast();

  /// Messages reçus pendant que l'app est ouverte (les providers rafraîchissent alors leurs données).
  Stream<RemoteMessage> get foreground => _fg.stream;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
      final m = FirebaseMessaging.instance;
      await m.requestPermission();
      await m.setForegroundNotificationPresentationOptions(alert: false, badge: false, sound: false);
      FirebaseMessaging.onMessage.listen(_fg.add);
      enabled = true;
    } catch (e) {
      debugPrint('Firebase non configuré : notifications push désactivées ($e)');
      enabled = false;
    }
  }

  /// Client : s'abonne au sujet « promotions » (une seule notification pour tous).
  Future<void> subscribePromos() async {
    if (!enabled) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic('promotions');
    } catch (_) {}
  }

  /// Associe cet appareil à l'utilisateur connecté (pour les notifications de commande).
  Future<void> registerDevice(ApiClient api) async {
    if (!enabled) return;
    try {
      final t = await FirebaseMessaging.instance.getToken();
      if (t == null) return;
      _token = t;
      await api.post('/api/devices', {'token': t, 'platform': defaultTargetPlatform.name});
      if (!_refreshHooked) {
        _refreshHooked = true;
        FirebaseMessaging.instance.onTokenRefresh.listen((n) {
          _token = n;
          if (api.token != null) {
            api.post('/api/devices', {'token': n, 'platform': defaultTargetPlatform.name}).catchError((_) {});
          }
        });
      }
    } catch (_) {}
  }

  Future<void> unregisterDevice(ApiClient api) async {
    if (!enabled || _token == null) return;
    try {
      await api.delete('/api/devices', {'token': _token});
    } catch (_) {}
  }
}
