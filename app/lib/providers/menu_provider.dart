import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_client.dart';

class MenuProvider extends ChangeNotifier {
  MenuProvider(this._api) {
    load();
  }
  final ApiClient _api;

  List<String> categories = [];
  Map<String, List<Product>> products = {};
  bool loading = false;
  String? error;
  bool _disposed = false;

  Future<void> load() async {
    loading = true;
    error = null;
    if (!_disposed) notifyListeners();
    try {
      final d = await _api.get('/api/products') as Map<String, dynamic>;
      final cats = (d['categories'] as List).map((e) => e.toString()).toList();
      final raw = (d['products'] as Map?) ?? {};
      final map = <String, List<Product>>{};
      for (final c in cats) {
        map[c] = ((raw[c] as List?) ?? []).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      }
      categories = cats;
      products = map;
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    if (!_disposed) notifyListeners();
  }

  List<Product> get all => products.values.expand((e) => e).toList();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
