import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/config.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider(this._api) {
    refreshAll();
    _timer = Timer.periodic(const Duration(seconds: AppConfig.ordersPollSeconds), (_) => loadOrders());
    _sub = PushService.instance.foreground.listen((m) {
      if (m.data['type'] == 'new_order' || m.data['type'] == 'order') loadOrders();
    });
  }

  final ApiClient _api;
  Timer? _timer;
  StreamSubscription? _sub;
  bool _disposed = false;

  List<OrderModel> orders = [];
  AdminStats? stats;
  List<Product> products = [];
  List<Promotion> promos = [];
  bool ordersLoaded = false, productsLoaded = false, promosLoaded = false;
  String? error;
  Set<String>? _knownRefs;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refreshAll() => Future.wait([loadOrders(), loadProducts(), loadPromos()]);

  Future<void> loadOrders() async {
    try {
      final d = await _api.get('/api/admin/orders') as Map<String, dynamic>;
      final list = (d['orders'] as List).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
      final known = _knownRefs;
      if (known != null) {
        for (final o in list.where((o) => !known.contains(o.ref) && o.status == 'received')) {
          NotificationService.instance.showNewOrder(o);
        }
      }
      _knownRefs = list.map((o) => o.ref).toSet();
      orders = list;
      final s = await _api.get('/api/admin/stats') as Map<String, dynamic>;
      stats = AdminStats.fromJson(s);
      error = null;
    } catch (e) {
      error = e.toString();
    }
    ordersLoaded = true;
    _notify();
  }

  Future<void> loadProducts() async {
    try {
      final d = await _api.get('/api/admin/products') as Map<String, dynamic>;
      products = (d['products'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      error = e.toString();
    }
    productsLoaded = true;
    _notify();
  }

  Future<void> loadPromos() async {
    try {
      final d = await _api.get('/api/admin/promotions') as Map<String, dynamic>;
      promos = (d['promotions'] as List).map((e) => Promotion.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      error = e.toString();
    }
    promosLoaded = true;
    _notify();
  }

  // ---- Commandes ----
  Future<void> setOrderStatus(String ref, String status) async {
    await _api.patch('/api/admin/orders/${Uri.encodeComponent(ref)}/set-status', {'status': status});
    await loadOrders();
  }

  // ---- Produits ----
  Future<void> setAvailability(Product p, bool available) async {
    final i = products.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      products[i] = p.copyWith(available: available); // affichage immédiat
      _notify();
    }
    try {
      await _api.patch('/api/admin/products/${p.id}/availability', {'available': available});
    } catch (e) {
      await loadProducts(); // on remet l'état réel du serveur
      rethrow;
    }
  }

  Future<void> saveProduct({
    String? id,
    required String name,
    required String description,
    required String category,
    required int price,
    required String flavors,
    required bool available,
    String? imagePath,
    bool removeImage = false,
  }) async {
    await _api.postMultipart(
      id == null ? '/api/admin/products' : '/api/admin/products/$id',
      {
        'name': name,
        'description': description,
        'category': category,
        'basePrice': '$price',
        'flavors': flavors,
        'available': available ? '1' : '0',
        if (removeImage) 'removeImage': '1',
      },
      filePath: imagePath,
    );
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _api.delete('/api/admin/products/$id');
    products.removeWhere((p) => p.id == id);
    _notify();
  }

  // ---- Promotions ----
  Future<void> savePromo(int? id, Map<String, dynamic> body) async {
    if (id == null) {
      await _api.post('/api/admin/promotions', body);
    } else {
      await _api.put('/api/admin/promotions/$id', body);
    }
    await loadPromos();
  }

  Future<void> togglePromo(Promotion p) async {
    await _api.patch('/api/admin/promotions/${p.id}/toggle');
    await loadPromos();
  }

  Future<void> deletePromo(int id) async {
    await _api.delete('/api/admin/promotions/$id');
    promos.removeWhere((p) => p.id == id);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
