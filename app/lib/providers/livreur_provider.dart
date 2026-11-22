import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/config.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';

/// Commandes en cours pour le livreur (toutes sauf « Terminée »).
class LivreurProvider extends ChangeNotifier {
  LivreurProvider(this._api) {
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
    _sub = PushService.instance.foreground.listen((m) {
      final t = m.data['type'];
      if (t == 'new_order' || t == 'order') refresh();
    });
  }

  final ApiClient _api;
  Timer? _timer;
  StreamSubscription? _sub;
  bool _disposed = false;

  List<OrderModel> orders = [];
  bool loaded = false;
  String? error;
  Set<String>? _known;

  int count(String status) => orders.where((o) => o.status == status).length;

  Future<void> refresh() async {
    try {
      final d = await _api.get('/api/orders/active') as Map<String, dynamic>;
      final list = (d['orders'] as List).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
      final known = _known;
      if (known != null) {
        for (final o in list.where((o) => !known.contains(o.ref) && o.status == 'received')) {
          NotificationService.instance.showNewOrder(o);
        }
      }
      _known = list.map((o) => o.ref).toSet();
      orders = list;
      error = null;
    } catch (e) {
      error = e.toString();
    }
    loaded = true;
    if (!_disposed) notifyListeners();
  }

  /// Fait avancer la commande d'une étape (received -> preparing -> delivering ; client_confirmed -> delivered).
  Future<void> advance(String ref) async {
    await _api.patch('/api/orders/${Uri.encodeComponent(ref)}/status');
    await refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
