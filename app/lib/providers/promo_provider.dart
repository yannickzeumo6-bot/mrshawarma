import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';

class PromoProvider extends ChangeNotifier {
  PromoProvider(this._api) {
    refresh();
    _timer = Timer.periodic(const Duration(seconds: AppConfig.promoPollSeconds), (_) => refresh());
    _sub = PushService.instance.foreground.listen((m) {
      if (m.data['type'] == 'promo') refresh();
    });
  }

  final ApiClient _api;
  Timer? _timer;
  StreamSubscription? _sub;
  bool _disposed = false;

  static const _kSeen = 'promo_seen_ids';
  static const _kRead = 'promo_read_ids';

  List<Promotion> promos = [];
  Set<int> _read = {};
  bool loaded = false;

  int get unreadCount => promos.where((p) => !_read.contains(p.id)).length;

  Future<void> refresh() async {
    try {
      final d = await _api.get('/api/promotions') as Map<String, dynamic>;
      final list = (d['promotions'] as List).map((e) => Promotion.fromJson(e as Map<String, dynamic>)).toList();
      final prefs = await SharedPreferences.getInstance();
      final seenRaw = prefs.getStringList(_kSeen);
      _read = (prefs.getStringList(_kRead) ?? []).map(int.parse).toSet();

      // Notification locale seulement pour une promo jamais vue ET récente
      // (une promo plus ancienne a déjà été annoncée par le push Firebase).
      if (seenRaw != null) {
        final seen = seenRaw.map(int.parse).toSet();
        final limit = DateTime.now().subtract(const Duration(minutes: AppConfig.freshPromoMinutes));
        for (final p in list.where((p) => !seen.contains(p.id) && p.createdAt.isAfter(limit))) {
          NotificationService.instance.showPromo(p);
        }
      }
      await prefs.setStringList(_kSeen, list.map((p) => '${p.id}').toList());
      promos = list;
      loaded = true;
      if (!_disposed) notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    _read = promos.map((p) => p.id).toSet();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kRead, _read.map((e) => '$e').toList());
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
