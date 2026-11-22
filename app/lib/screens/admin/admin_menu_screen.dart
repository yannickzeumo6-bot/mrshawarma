import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/common.dart';
import 'product_form_screen.dart';

class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  void _open(BuildContext context, [Product? p]) {
    final admin = context.read<AdminProvider>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(value: admin, child: ProductFormScreen(product: p)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    if (!admin.productsLoaded) return const SkeletonList();

    final cats = <String, List<Product>>{};
    for (final p in admin.products) {
      cats.putIfAbsent(p.category, () => []).add(p);
    }
    final keys = cats.keys.toList()
      ..sort((a, b) {
        const order = {'shawarma': 1, 'boissons': 2};
        final c = (order[a] ?? 99).compareTo(order[b] ?? 99);
        return c != 0 ? c : a.compareTo(b);
      });

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Brand.gold,
        foregroundColor: Brand.ink,
        onPressed: () => _open(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: Brand.gold,
        onRefresh: admin.loadProducts,
        child: admin.products.isEmpty
            ? ListView(children: [const SizedBox(height: 90), EmptyState(emoji: '🍽️', title: admin.error ?? 'Menu vide', subtitle: 'Ajoute ton premier produit.')])
            : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 90), children: [
                for (final k in keys) ...[
                  SectionTitle(categoryLabel(k)),
                  for (final p in cats[k]!)
                    Panel(
                      enterIndex: cats[k]!.indexOf(p),
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _open(context, p),
                        child: Row(children: [
                          ProductImage(emoji: p.emoji, url: p.imageUrl, asset: p.assetImage, size: 62, radius: 14, dim: !p.available),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(fcfa(p.basePrice), style: const TextStyle(color: Brand.gold, fontWeight: FontWeight.w800)),
                              Text(p.available ? 'Disponible' : 'Épuisé', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.available ? Brand.ok : Brand.danger)),
                            ]),
                          ),
                          Switch(
                            value: p.available,
                            onChanged: (v) async {
                              try {
                                await admin.setAvailability(p, v);
                              } catch (e) {
                                if (context.mounted) snack(context, e.toString());
                              }
                            },
                          ),
                        ]),
                      ),
                    ),
                ],
              ]),
      ),
    );
  }
}
