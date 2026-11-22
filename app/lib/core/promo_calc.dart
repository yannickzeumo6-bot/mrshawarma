import '../models/models.dart';
import '../providers/cart_provider.dart';

class PromoResult {
  final Promotion? promo;
  final int amount;
  const PromoResult(this.promo, this.amount);
}

/// Miroir exact de PromotionService.php (le serveur reste l'autorité).
int promoAmount(Promotion p, List<CartLine> lines) {
  var eligible = 0;
  for (final l in lines) {
    if (p.productId != null) {
      if (l.product.id != p.productId) continue;
    } else if (p.category != null) {
      if (l.product.category != p.category) continue;
    }
    eligible += l.product.basePrice * l.qty;
  }
  if (eligible <= 0) return 0;
  switch (p.discountType) {
    case 'percent':
      return eligible * (p.discountValue > 100 ? 100 : p.discountValue) ~/ 100;
    case 'fixed':
      return p.discountValue < eligible ? p.discountValue : eligible;
    default:
      return 0;
  }
}

PromoResult bestPromo(List<CartLine> lines, List<Promotion> promos, {required int cap}) {
  final now = DateTime.now();
  Promotion? best;
  var bestAmount = 0;
  for (final p in promos) {
    if (!p.active) continue;
    if (p.startsAt != null && now.isBefore(p.startsAt!)) continue;
    if (p.endsAt != null && now.isAfter(p.endsAt!)) continue;
    final a = promoAmount(p, lines);
    if (a > bestAmount) {
      best = p;
      bestAmount = a;
    }
  }
  if (bestAmount > cap) bestAmount = cap < 0 ? 0 : cap;
  return PromoResult(bestAmount > 0 ? best : null, bestAmount);
}
