import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/phone.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/fx.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String? _filter;

  static const _filters = <String?, String>{
    null: 'Toutes',
    'received': 'Reçues',
    'preparing': 'Préparation',
    'delivering': 'Livraison',
    'client_confirmed': 'À clôturer',
    'delivered': 'Terminées',
  };

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    if (!admin.ordersLoaded) return const SkeletonList(count: 4);
    final orders = admin.orders.where((o) => _filter == null || o.status == _filter).toList();
    final s = admin.stats;

    return RefreshIndicator(
      color: Brand.gold,
      onRefresh: admin.loadOrders,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        if (s != null)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: [
              FadeSlideIn(child: _Stat("Aujourd'hui", s.todayRevenue, fcfa, '${s.todayOrders} commande(s)')),
              FadeSlideIn(delay: stagger(1), child: _Stat('En cours', s.inProgress, (v) => '$v', 'à traiter')),
              FadeSlideIn(delay: stagger(2), child: _Stat('CA total', s.totalRevenue, fcfa, 'commandes terminées')),
              FadeSlideIn(delay: stagger(3), child: _Stat('Livrées', s.delivered, (v) => '$v', 'sur ${s.totalOrders} au total')),
            ],
          ),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final e in _filters.entries)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(e.value), selected: _filter == e.key, onSelected: (_) => setState(() => _filter = e.key)),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        if (orders.isEmpty)
          Padding(padding: const EdgeInsets.only(top: 40), child: EmptyState(emoji: '🧾', title: admin.error ?? 'Aucune commande'))
        else
          for (final e in orders.asMap().entries) FadeSlideIn(key: ValueKey('ao-${e.value.ref}'), delay: stagger(e.key), child: _AdminOrderCard(e.value)),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.fmt, this.sub);
  final String label, sub;
  final int value;
  final String Function(int) fmt;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Brand.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: Brand.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: const TextStyle(color: Brand.dim, fontSize: 12)),
          FittedBox(fit: BoxFit.scaleDown, child: CountUp(value: value, format: fmt, style: Brand.display(23, color: Brand.gold, spacing: 0.5))),
          Text(sub, style: const TextStyle(color: Brand.dim, fontSize: 11)),
        ]),
      );
}

class _AdminOrderCard extends StatefulWidget {
  const _AdminOrderCard(this.o);
  final OrderModel o;
  @override
  State<_AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<_AdminOrderCard> {
  bool _busy = false;

  static const _next = {
    'received': ('preparing', 'Passer en préparation'),
    'preparing': ('delivering', 'Envoyer en livraison'),
    'delivering': ('client_confirmed', 'Forcer : réception confirmée'),
    'client_confirmed': ('delivered', 'Clôturer la commande'),
  };

  Future<void> _advance() async {
    final o = widget.o;
    final n = _next[o.status]!;
    if (o.status == 'delivering') {
      final ok = await confirmDialog(context, 'Forcer la confirmation ?',
          "Le client n'a pas encore confirmé la réception de ${o.ref}. À n'utiliser que si la commande est bien livrée.");
      if (!ok) return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AdminProvider>().setOrderStatus(o.ref, n.$1);
    } catch (e) {
      if (mounted) snack(context, e.toString());
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.o;
    final next = _next[o.status];
    final done = o.status == 'delivered';
    return Panel(
      highlight: o.status == 'received',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(o.ref, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (o.status == 'received') const Padding(padding: EdgeInsets.only(right: 4), child: PulseDot(color: Brand.flame, size: 8)),
            Pill(o.statusLabel, color: done ? Brand.ok : Brand.gold),
          ]),
        ]),
        const SizedBox(height: 2),
        Text('${o.clientName ?? 'Client'}${o.clientPhone != null ? ' · ${prettyPhone(o.clientPhone!)}' : ''} · ${dateTimeFr(o.placed)}', style: const TextStyle(color: Brand.dim, fontSize: 12.5)),
        const SizedBox(height: 8),
        for (final it in o.items)
          Text('${it['qty']} × ${it['name']}${(it['options'] ?? '').toString().isNotEmpty ? ' · ${it['options']}' : ''}', style: const TextStyle(fontSize: 13.5)),
        const SizedBox(height: 8),
        Text('📍 ${o.address}${o.distanceKm != null ? '  (${o.distanceKm} km)' : ''}', style: const TextStyle(color: Brand.dim, fontSize: 12.5)),
        if (o.promoTitle != null && o.promoAmount > 0)
          Text('🎉 ${o.promoTitle} : -${fcfa(o.promoAmount)}', style: const TextStyle(color: Brand.gold, fontSize: 12.5)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(o.paymentLabel, style: const TextStyle(color: Brand.dim, fontSize: 12.5)),
          Text(fcfa(o.total), style: const TextStyle(fontWeight: FontWeight.w900, color: Brand.gold, fontSize: 16)),
        ]),
        if (next != null) ...[
          const SizedBox(height: 10),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44), backgroundColor: o.status == 'delivering' ? Brand.line : Brand.gold, foregroundColor: o.status == 'delivering' ? Brand.cream : Brand.ink),
            onPressed: _busy ? null : _advance,
            child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)) : Text(next.$2),
          ),
        ],
      ]),
    );
  }
}
