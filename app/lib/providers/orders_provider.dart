import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/config.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';

class OrdersProvider extends ChangeNotifier {
  OrdersProvider(this._api) {
    refresh();
    _timer = Timer.periodic(const Duration(seconds: AppConfig.ordersPollSeconds), (_) => refresh());
    _sub = PushService.instance.foreground.listen((m) {
      final t = m.data['type'];
      if (t == 'order' || t == 'new_order') refresh();
    });
  }

  final ApiClient _api;
  Timer? _timer;
  StreamSubscription? _sub;
  bool _disposed = false;

  List<OrderModel> orders = [];
  bool loaded = false;
  String? error;
  Map<String, String>? _last;

  Future<void> refresh() async {
    try {
      final d = await _api.get('/api/orders/mine') as Map<String, dynamic>;
      final list = (d['orders'] as List).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
      final prev = _last;
      if (prev != null) {
        for (final o in list) {
          final old = prev[o.ref];
          if (old != null && old != o.status) NotificationService.instance.showOrderUpdate(o.ref, o.statusLabel);
        }
      }
      _last = {for (final o in list) o.ref: o.status};
      orders = list;
      error = null;
    } catch (e) {
      error = e.toString();
    }
    loaded = true;
    if (!_disposed) notifyListeners();
  }

  Future<void> confirmReceipt(String ref) async {
    await _api.patch('/api/orders/${Uri.encodeComponent(ref)}/confirm-receipt');
    await refresh();
  }

  Future<OrderModel> place(Map<String, dynamic> payload) async {
    final d = await _api.post('/api/orders', payload) as Map<String, dynamic>;
    final order = OrderModel.fromJson(d['order'] as Map<String, dynamic>);
    await refresh();
    return order;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
