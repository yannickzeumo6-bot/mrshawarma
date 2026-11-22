import 'package:flutter/foundation.dart';

/// 0 = Menu, 1 = Promos, 2 = Panier, 3 = Commandes
class NavController extends ChangeNotifier {
  int index = 0;
  void go(int i) {
    if (i == index) return;
    index = i;
    notifyListeners();
  }
}
