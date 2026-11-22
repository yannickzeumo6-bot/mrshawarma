import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../core/config.dart';
import '../models/models.dart';

class CartLine {
  final Product product;
  final String? flavor;
  int qty;
  CartLine(this.product, {this.flavor, this.qty = 1});
  String get key => '${product.id}|${flavor ?? ''}';
  int get total => product.basePrice * qty;
}

class CartProvider extends ChangeNotifier {
  final List<CartLine> _lines = [];
  List<CartLine> get lines => List.unmodifiable(_lines);

  int get count => _lines.fold(0, (s, l) => s + l.qty);
  int get subtotal => _lines.fold(0, (s, l) => s + l.total);
  int qtyOf(String productId) => _lines.where((l) => l.product.id == productId).fold(0, (s, l) => s + l.qty);

  /// Fidélité : 1 shawarma offert tous les 10 (le moins cher), comme le serveur.
  int get freeShawarmas =>
      _lines.where((l) => l.product.category == 'shawarma').fold(0, (s, l) => s + l.qty) ~/ AppConfig.promoQtyPerFree;

  int get loyaltyDiscount {
    final sh = _lines.where((l) => l.product.category == 'shawarma').toList();
    if (freeShawarmas == 0 || sh.isEmpty) return 0;
    final d = freeShawarmas * sh.map((l) => l.product.basePrice).reduce(math.min);
    return math.min(d, subtotal);
  }

  void add(Product p, {String? flavor}) {
    final i = _lines.indexWhere((l) => l.key == '${p.id}|${flavor ?? ''}');
    if (i >= 0) {
      _lines[i].qty++;
    } else {
      _lines.add(CartLine(p, flavor: flavor));
    }
    notifyListeners();
  }

  void inc(CartLine l) {
    l.qty++;
    notifyListeners();
  }

  void dec(CartLine l) {
    if (l.qty <= 1) {
      _lines.remove(l);
    } else {
      l.qty--;
    }
    notifyListeners();
  }

  /// Pour le stepper d'une tuile produit sans saveur.
  void decProduct(Product p) {
    final i = _lines.indexWhere((l) => l.product.id == p.id);
    if (i >= 0) dec(_lines[i]);
  }

  /// Retire du panier les produits devenus indisponibles ; renvoie leurs noms.
  List<String> dropUnavailable(Map<String, Product> fresh) {
    final removed = <String>[];
    _lines.removeWhere((l) {
      final f = fresh[l.product.id];
      final gone = f == null || !f.available;
      if (gone) removed.add(l.product.name);
      return gone;
    });
    if (removed.isNotEmpty) notifyListeners();
    return removed;
  }

  void remove(CartLine l) {
    _lines.remove(l);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toPayload() => _lines
      .map((l) => {
            'productId': l.product.id,
            'qty': l.qty,
            'customization': l.flavor == null ? <String, dynamic>{} : {'saveur': l.flavor},
          })
      .toList();
}
