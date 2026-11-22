import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/models.dart';
import 'push_service.dart';

/// Notifications locales affichées quand l'app est ouverte.
/// (App fermée = notifications push Firebase, voir PushService.)
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    try {
      await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ));
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
          'promotions', 'Promotions', importance: Importance.high));
      await android?.createNotificationChannel(const AndroidNotificationChannel(
          'orders', 'Suivi des commandes', importance: Importance.high));
      await android?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Avec Firebase actif, l'arrière-plan est géré par le système : on n'affiche
  /// de notification locale que si l'app est au premier plan (évite les doublons).
  bool get _canShow {
    if (!_ready) return false;
    if (!PushService.instance.enabled) return true;
    final s = WidgetsBinding.instance.lifecycleState;
    return s == null || s == AppLifecycleState.resumed;
  }

  NotificationDetails _d(String id, String name) => NotificationDetails(
        android: AndroidNotificationDetails(id, name, importance: Importance.high, priority: Priority.high),
        iOS: const DarwinNotificationDetails(),
      );

  Future<void> showPromo(Promotion p) async {
    if (!_canShow) return;
    await _plugin.show(
      1000 + p.id,
      '🔥 ${p.badge} · ${p.title}',
      p.description.isEmpty ? "Une nouvelle promotion vient d'arriver chez Mr. Shawarma !" : p.description,
      _d('promotions', 'Promotions'),
    );
  }

  Future<void> showOrderUpdate(String ref, String label) async {
    if (!_canShow) return;
    await _plugin.show(ref.hashCode & 0x7fffffff, 'Commande $ref', label, _d('orders', 'Suivi des commandes'));
  }

  Future<void> showNewOrder(OrderModel o) async {
    if (!_canShow) return;
    await _plugin.show(
      ref2id(o.ref),
      'Nouvelle commande ${o.ref}',
      '${o.clientName ?? 'Client'} · ${o.address}',
      _d('orders', 'Suivi des commandes'),
    );
  }

  int ref2id(String r) => (r.hashCode & 0x7fffffff) + 7;
}
