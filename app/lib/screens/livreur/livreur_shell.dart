import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/livreur_provider.dart';
import '../../services/api_client.dart';
import '../../services/push_service.dart';
import '../../widgets/common.dart';
import '../../widgets/fx.dart';

class LivreurShell extends StatefulWidget {
  const LivreurShell({super.key});
  @override
  State<LivreurShell> createState() => _LivreurShellState();
}

class _LivreurShellState extends State<LivreurShell> {
  String? _filter;

  static const _filters = <String?, String>{
    null: 'Toutes',
    'received': 'Nouvelles',
    'preparing': 'Préparation',
    'delivering': 'En route',
    'client_confirmed': 'À clôturer',
  };

  @override
  void initState() {
    super.initState();
    PushService.instance.registerDevice(context.read<ApiClient>()); // alertes « nouvelle commande »
  }

  @override
  Widget build(BuildContext context) {
    final lv = context.watch<LivreurProvider>();
    final auth = context.read<AuthProvider>();
    final orders = lv.orders.where((o) => _filter == null || o.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/logo.png', width: 30, height: 30),
          const SizedBox(width: 9),
          Text('LIVREUR', style: Brand.display(21, color: Brand.gold, spacing: 1.4)),
        ]),
        actions: [
          IconButton(onPressed: lv.refresh, icon: const Icon(Icons.refresh)),
          PopupMenuButton<String>(
            color: Brand.surface,
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (v) {
              if (v == 'logout') auth.logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text(auth.user?.name ?? '', style: const TextStyle(color: Brand.dim))),
              const PopupMenuItem(value: 'logout', child: Text('Se déconnecter')),
            ],
          ),
        ],
      ),
      body: !lv.loaded
          ? const SkeletonList(count: 3)
          : RefreshIndicator(
              color: Brand.gold,
              onRefresh: lv.refresh,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                FadeSlideIn(
                  child: Row(children: [
                    Expanded(child: _Kpi('Nouvelles', lv.count('received'), Brand.flame, live: lv.count('received') > 0)),
                    const SizedBox(width: 10),
                    Expanded(child: _Kpi('En route', lv.count('delivering'), Brand.gold)),
                    const SizedBox(width: 10),
                    Expanded(child: _Kpi('À clôturer', lv.count('client_confirmed'), Brand.ok)),
                  ]),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 42,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: EmptyState(emoji: '🛵', title: lv.error ?? 'Aucune commande à livrer', subtitle: lv.error == null ? 'Tu seras alerté dès qu\'une commande arrive.' : null),
                  )
                else
                  for (final e in orders.asMap().entries)
                    FadeSlideIn(key: ValueKey('lv-${e.value.ref}'), delay: stagger(e.key), child: _DeliveryCard(e.value)),
              ]),
            ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.color, {this.live = false});
  final String label;
  final int value;
  final Color color;
  final bool live;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(color: Brand.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: Brand.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(color: Brand.dim, fontSize: 11.5), overflow: TextOverflow.ellipsis)),
            if (live) PulseDot(color: color, size: 6),
          ]),
          CountUp(value: value, format: (v) => '$v', style: Brand.display(30, color: color, spacing: 0.5)),
        ]),
      );
}

class _DeliveryCard extends StatefulWidget {
  const _DeliveryCard(this.o);
  final OrderModel o;
  @override
  State<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<_DeliveryCard> {
  bool _busy = false;

  static const _actions = {
    'received': 'Prendre en charge',
    'preparing': 'Partir en livraison',
    'client_confirmed': 'Clôturer la livraison',
  };

  Future<void> _advance() async {
    setState(() => _busy = true);
    try {
      await context.read<LivreurProvider>().advance(widget.o.ref);
    } catch (e) {
      if (mounted) snack(context, e.toString());
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _route() async {
    final o = widget.o;
    final uri = (o.lat != null && o.lng != null)
        ? Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${o.lat},${o.lng}&travelmode=driving')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(o.address)}');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) snack(context, "Impossible d'ouvrir l'itinéraire.");
    } catch (_) {
      if (mounted) snack(context, "Impossible d'ouvrir l'itinéraire.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.o;
    final action = _actions[o.status];
    final waiting = o.status == 'delivering';
    final cash = o.paymentMethod == 'cash';

    return Panel(
      highlight: o.status == 'received',
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(o.ref, style: Brand.display(22, spacing: 0.8)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (o.status == 'received') const Padding(padding: EdgeInsets.only(right: 4), child: PulseDot(color: Brand.flame, size: 8)),
            Pill(o.statusLabel, color: o.status == 'client_confirmed' ? Brand.ok : Brand.gold),
          ]),
        ]),
        const SizedBox(height: 4),
        Text('${o.clientName ?? 'Client'} · ${dateTimeFr(o.placed)}', style: const TextStyle(color: Brand.dim, fontSize: 12.5)),
        const SizedBox(height: 12),
        for (final it in o.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('${it['qty']} × ${it['name']}${(it['summary'] ?? '').toString().startsWith('Saveur') ? ' · ${it['summary']}' : ''}', style: const TextStyle(fontSize: 14)),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Brand.ink, borderRadius: BorderRadius.circular(14), border: Border.all(color: Brand.line)),
          child: Row(children: [
            const Icon(Icons.place, color: Brand.gold, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(o.address, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
            if (o.distanceKm != null) Pill('${o.distanceKm} km', color: Brand.gold),
          ]),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(cash ? '💵 À encaisser' : '✅ ${o.paymentLabel}', style: TextStyle(color: cash ? Brand.gold : Brand.ok, fontWeight: FontWeight.w700, fontSize: 13)),
          Text(fcfa(o.total), style: Brand.display(21, color: Brand.gold, spacing: 0.4)),
        ]),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _route, icon: const Icon(Icons.navigation_outlined, size: 18), label: const Text('Ouvrir l\'itinéraire')),
        const SizedBox(height: 10),
        if (waiting)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Brand.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Brand.gold.withOpacity(0.4))),
            child: const Row(children: [
              Breathe(child: Icon(Icons.hourglass_top, color: Brand.gold)),
              SizedBox(width: 12),
              Expanded(child: Text('En attente de la confirmation de réception du client', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            ]),
          )
        else if (action != null)
          GoldButton(label: action, busy: _busy, onPressed: _advance, icon: o.status == 'client_confirmed' ? Icons.verified : Icons.arrow_forward),
      ]),
    );
  }
}
