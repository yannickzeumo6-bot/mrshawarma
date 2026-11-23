import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/nav_controller.dart';
import '../../providers/promo_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/fx.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String? _cat; // null = tout
  String _query = '';
  final _pageCtl = PageController(viewportFraction: 0.9);
  int _page = 0;

  Timer? _auto;

  @override
  void initState() {
    super.initState();
    // Défilement automatique des promotions
    _auto = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageCtl.hasClients) return;
      final n = context.read<PromoProvider>().promos.length;
      if (n < 2) return;
      _pageCtl.animateToPage((_page + 1) % n, duration: const Duration(milliseconds: 650), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _pageCtl.dispose();
    super.dispose();
  }

  Future<void> _add(Product p) async {
    final cart = context.read<CartProvider>();
    String? flavor;
    if (p.hasFlavors && p.flavors.isNotEmpty) {
      flavor = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Brand.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const Text('Choisis ta saveur', style: TextStyle(color: Brand.dim)),
              const SizedBox(height: 16),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (final f in p.flavors)
                  ActionChip(
                    label: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Text(f)),
                    onPressed: () => Navigator.pop(context, f),
                  ),
              ]),
            ]),
          ),
        ),
      );
      if (flavor == null) return;
    }
    String? piment;
    if (p.category == 'shawarma') {
      piment = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Brand.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const Text('Avec ou sans piment ?', style: TextStyle(color: Brand.dim)),
              const SizedBox(height: 16),
              Wrap(spacing: 10, runSpacing: 10, children: [
                ActionChip(
                  label: const Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Text('🌶️ Avec piment')),
                  onPressed: () => Navigator.pop(context, 'avec'),
                ),
                ActionChip(
                  label: const Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Text('Sans piment')),
                  onPressed: () => Navigator.pop(context, 'sans'),
                ),
              ]),
            ]),
          ),
        ),
      );
      if (piment == null) return;
    }
    HapticFeedback.lightImpact();
    cart.add(p, flavor: flavor, piment: piment);
  }

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<MenuProvider>();
    final promos = context.watch<PromoProvider>();
    final cart = context.watch<CartProvider>();
    final name = context.read<AuthProvider>().user?.firstName ?? '';

    if (menu.loading && menu.categories.isEmpty) return const SkeletonList();
    if (menu.categories.isEmpty) {
      return EmptyState(
        emoji: '📡',
        title: menu.error ?? 'Menu indisponible.',
        action: FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(170, 46)),
          onPressed: menu.load,
          child: const Text('Réessayer'),
        ),
      );
    }

    final q = _query.trim().toLowerCase();
    final cats = _cat == null ? menu.categories : [_cat!];
    final sections = <String, List<Product>>{};
    for (final c in cats) {
      final items = (menu.products[c] ?? [])
          .where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q))
          .toList();
      if (items.isNotEmpty) sections[c] = items;
    }

    return Stack(children: [
      RefreshIndicator(
        color: Brand.gold,
        onRefresh: () async => Future.wait([menu.load(), promos.refresh()]),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 4, 16, cart.count > 0 ? 96 : 24),
          children: [
            FadeSlideIn(child: _HeroCard(name: name)),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(hintText: 'Rechercher un plat ou une boisson', prefixIcon: Icon(Icons.search)),
            ),
            if (promos.promos.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 112,
                child: PageView(
                  controller: _pageCtl,
                  padEnds: false,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [for (final p in promos.promos) _PromoBanner(p, onTap: () => context.read<NavController>().go(1))],
                ),
              ),
              if (promos.promos.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < promos.promos.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(color: i == _page ? Brand.gold : Brand.line, borderRadius: BorderRadius.circular(3)),
                      ),
                  ]),
                ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                _CatChip(label: 'Tout', emoji: '🔥', selected: _cat == null, onTap: () => setState(() => _cat = null)),
                for (final c in menu.categories)
                  _CatChip(label: categoryLabel(c), emoji: c == 'shawarma' ? '🌯' : (c == 'boissons' ? '🥤' : '🍴'), selected: _cat == c, onTap: () => setState(() => _cat = c)),
              ]),
            ),
            const SizedBox(height: 8),
            if (sections.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 40), child: EmptyState(emoji: '🔍', title: 'Aucun résultat', subtitle: 'Essaie un autre mot.')),
            for (final e in sections.entries) ...[
              if (_cat == null) SectionTitle(categoryLabel(e.key)),
              for (final entry in e.value.asMap().entries)
                FadeSlideIn(
                  key: ValueKey('tile-${entry.value.id}'),
                  delay: stagger(entry.key),
                  child: _ProductTile(entry.value, onAdd: () => _add(entry.value)),
                ),
            ],
            const SizedBox(height: 8),
            const Center(
              child: Text('Service sur place · À emporter · Livraison disponible', style: TextStyle(color: Brand.dim, fontSize: 12)),
            ),
          ],
        ),
      ),
      Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: AnimatedSlide(
            offset: cart.count > 0 ? Offset.zero : const Offset(0, 2.2),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            child: Pop(
              trigger: cart.count,
              child: GestureDetector(
            onTap: () => context.read<NavController>().go(2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: Brand.goldGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Brand.gold.withOpacity(0.35), blurRadius: 22, offset: const Offset(0, 8))],
              ),
              child: Row(children: [
                const Icon(Icons.shopping_bag, color: Brand.ink),
                const SizedBox(width: 10),
                Text('${cart.count} article${cart.count > 1 ? 's' : ''}', style: const TextStyle(color: Brand.ink, fontWeight: FontWeight.w800)),
                const Spacer(),
                CountUp(value: cart.subtotal, format: fcfa, style: const TextStyle(color: Brand.ink, fontWeight: FontWeight.w900)),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: Brand.ink),
              ]),
            ),
          ),
          ),
          ),
        ),
    ]);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Container(
        height: 156,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Brand.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Brand.gold.withOpacity(0.35)),
        ),
        child: Stack(children: [
          Positioned(right: 0, top: 0, bottom: 0, width: 230, child: Image.asset('assets/images/hero.jpg', fit: BoxFit.cover, alignment: Alignment.centerLeft)),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Brand.ink, Color(0xF00A0806), Color(0x660A0806), Color(0x000A0806)], stops: [0, 0.42, 0.62, 1]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(name.isEmpty ? 'Salut 👋' : 'Salut $name 👋', style: const TextStyle(color: Brand.dim, fontSize: 13)),
              const SizedBox(height: 2),
              Text("QU'EST-CE QU'ON\nMANGE ?", style: Brand.display(27, height: 1.05)),
              const SizedBox(height: 6),
              Text("Le secret c'est la sauce", style: TextStyle(color: Brand.gold.withOpacity(0.95), fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          ),
        ]),
      );
}

class _CatChip extends StatelessWidget {
  const _CatChip({required this.label, required this.emoji, required this.selected, required this.onTap});
  final String label, emoji;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: selected ? Brand.goldGradient : null,
              color: selected ? null : Brand.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: selected ? Colors.transparent : Brand.line),
            ),
            child: Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 7),
              Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: selected ? Brand.ink : Brand.cream)),
            ]),
          ),
        ),
      );
}

class _ProductTile extends StatelessWidget {
  const _ProductTile(this.p, {required this.onAdd});
  final Product p;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final qty = cart.qtyOf(p.id);
    final off = !p.available;

    Widget action;
    if (off) {
      action = const Pill('Épuisé', color: Brand.danger);
    } else if (qty > 0 && !p.hasFlavors && p.category != 'shawarma') {
      action = Container(
        decoration: BoxDecoration(color: Brand.ink, borderRadius: BorderRadius.circular(22), border: Border.all(color: Brand.gold.withOpacity(0.55))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(visualDensity: VisualDensity.compact, onPressed: () => cart.decProduct(p), icon: const Icon(Icons.remove, size: 18)),
          Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900)),
          IconButton(visualDensity: VisualDensity.compact, onPressed: onAdd, icon: const Icon(Icons.add, size: 18, color: Brand.gold)),
        ]),
      );
    } else {
      action = Pressable(
        onTap: onAdd,
        scale: 0.8,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: Brand.goldGradient,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Brand.gold.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: const Icon(Icons.add, color: Brand.ink, size: 24),
        ),
      );
    }

    return Container(
      height: 122,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Brand.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Brand.line),
      ),
      child: Row(children: [
        Stack(children: [
          ProductImage(emoji: p.emoji, url: p.imageUrl, asset: p.assetImage, width: 126, height: 122, radius: 0, dim: off),
          if (p.isDouble && !off)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Brand.flame, borderRadius: BorderRadius.circular(10)),
                child: const Text('DOUBLE VIANDE', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.4)),
              ),
            ),
        ]),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, height: 1.2, color: off ? Brand.dim : Brand.cream)),
                if (p.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(p.description.replaceFirst('Double viande · ', ''), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Brand.dim, fontSize: 11.5, height: 1.25)),
                  ),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                PriceBadge(p.basePrice, muted: off),
                action,
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner(this.p, {required this.onTap});
  final Promotion p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: Brand.flameGradient,
            boxShadow: [BoxShadow(color: Brand.flame.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: Brand.ink, borderRadius: BorderRadius.circular(14)),
              child: Text(p.badge, style: Brand.display(21, color: Brand.gold)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: Colors.white, height: 1.2)),
                if (p.description.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 2), child: Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12))),
              ]),
            ),
          ]),
        ),
      );
}
