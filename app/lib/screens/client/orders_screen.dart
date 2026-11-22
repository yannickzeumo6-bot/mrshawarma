import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/fx.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrdersProvider>();
    if (!op.loaded) return const SkeletonList(count: 3);
    return RefreshIndicator(
      color: Brand.gold,
      onRefresh: op.refresh,
      child: op.orders.isEmpty
          ? ListView(children: [
              const SizedBox(height: 90),
              EmptyState(emoji: '🧾', title: op.error ?? 'Aucune commande pour le moment', subtitle: op.error == null ? 'Tes commandes apparaîtront ici.' : null),
            ])
          : ListView(padding: const EdgeInsets.all(16), children: [for (final e in op.orders.asMap().entries) FadeSlideIn(key: ValueKey('o-${e.value.ref}'), delay: stagger(e.key), child: _OrderCard(e.value))]),
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard(this.o);
  final OrderModel o;
  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await context.read<OrdersProvider>().confirmReceipt(widget.o.ref);
    } catch (e) {
      if (mounted) snack(context, e.toString());
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.o;
    final done = o.status == 'delivered';
    const icons = [Icons.receipt_long, Icons.soup_kitchen, Icons.delivery_dining, Icons.verified, Icons.check_circle];

    return Panel(
      highlight: !done,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(o.ref, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (!done) const Padding(padding: EdgeInsets.only(right: 4), child: PulseDot(color: Brand.gold, size: 7)),
            Pill(o.statusLabel, color: done ? Brand.ok : Brand.gold),
          ]),
        ]),
        Text(dateTimeFr(o.placed), style: const TextStyle(color: Brand.dim, fontSize: 12)),
        const SizedBox(height: 14),
        // Frise de progression
        Row(children: [
          for (var i = 0; i < 5; i++) ...[
            Breathe(
              active: i == o.step && !done,
              amount: 0.14,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 30,
                height: 30,
                decoration: BoxDecoration(shape: BoxShape.circle, color: i <= o.step ? Brand.gold : Brand.ink, border: Border.all(color: i <= o.step ? Brand.gold : Brand.line)),
                child: Icon(icons[i], size: 16, color: i <= o.step ? Brand.ink : Brand.dim),
              ),
            ),
            if (i < 4)
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: i < o.step ? 1 : 0),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Stack(children: [
                    Container(height: 3, color: Brand.line),
                    FractionallySizedBox(widthFactor: v, child: Container(height: 3, color: Brand.gold)),
                  ]),
                ),
              ),
          ],
        ]),
        const SizedBox(height: 14),
        for (final it in o.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('${it['qty']} × ${it['name']}${(it['summary'] ?? '').toString().startsWith('Saveur') ? ' · ${it['summary']}' : ''}', style: const TextStyle(fontSize: 13.5)),
          ),
        const SizedBox(height: 8),
        Text('📍 ${o.address}', style: const TextStyle(color: Brand.dim, fontSize: 12.5)),
        if (o.promoTitle != null && o.promoAmount > 0)
          Text('🎉 ${o.promoTitle} : -${fcfa(o.promoAmount)}', style: const TextStyle(color: Brand.gold, fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${o.paymentLabel} · livraison ${o.deliveryFee == 0 ? 'gratuite' : fcfa(o.deliveryFee)}', style: const TextStyle(color: Brand.dim, fontSize: 12.5)),
          Text(fcfa(o.total), style: const TextStyle(fontWeight: FontWeight.w900, color: Brand.gold, fontSize: 16)),
        ]),
        if (o.status == 'delivering') ...[
          const SizedBox(height: 12),
          GoldButton(label: "J'ai reçu ma commande", icon: Icons.check_circle_outline, busy: _busy, onPressed: _confirm),
        ],
      ]),
    );
  }
}
