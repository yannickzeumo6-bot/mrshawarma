import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers/menu_provider.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/fx.dart';

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final promo = context.watch<PromoProvider>();
    final menu = context.read<MenuProvider>();

    String scope(p) {
      if (p.productId != null) {
        final m = menu.all.where((x) => x.id == p.productId);
        return m.isEmpty ? 'Sur un produit' : 'Sur : ${m.first.name}';
      }
      if (p.category != null) return 'Sur tous les ${categoryLabel(p.category!).toLowerCase()}';
      return p.discountType == 'info' ? '' : 'Sur tout le menu';
    }

    return RefreshIndicator(
      color: Brand.gold,
      onRefresh: promo.refresh,
      child: promo.promos.isEmpty
          ? ListView(children: const [
              SizedBox(height: 90),
              EmptyState(emoji: '🎁', title: 'Aucune promotion pour le moment', subtitle: "Tu seras notifié dès qu'il y en a une !"),
            ])
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final p in promo.promos)
                  Panel(
                    enterIndex: promo.promos.indexOf(p),
                    highlight: true,
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Shine(child: Pill(p.badge, filled: true)),
                        const SizedBox(width: 8),
                        if (scope(p).isNotEmpty) Expanded(child: Text(scope(p), style: const TextStyle(color: Brand.dim, fontSize: 12.5), overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 12),
                      Text(p.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                      if (p.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(p.description, style: const TextStyle(color: Brand.dim, height: 1.35)),
                      ],
                      if (p.discountType != 'info') ...[
                        const SizedBox(height: 10),
                        const Text("✅ Appliquée automatiquement à ton panier", style: TextStyle(color: Brand.ok, fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ],
                      if (p.endsAt != null) ...[
                        const SizedBox(height: 6),
                        Text("Valable jusqu'au ${dateTimeFr(p.endsAt!)}", style: const TextStyle(color: Brand.flame, fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ],
                    ]),
                  ),
              ],
            ),
    );
  }
}
