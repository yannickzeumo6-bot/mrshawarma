import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/promo_calc.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/nav_controller.dart';
import '../../providers/orders_provider.dart';
import '../../providers/promo_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/common.dart';
import '../../widgets/fx.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _address = TextEditingController();
  DeliveryQuote? _quote;
  String? _quoteSource; // 'gps' | 'address'
  String? _quoteError;
  bool _quoting = false, _placing = false;
  String _payment = 'cash';
  List<Map<String, dynamic>> _methods = [
    {'id': 'cash', 'label': 'Espèces à la livraison'}
  ];

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _loadMethods() async {
    try {
      final d = await context.read<ApiClient>().get('/api/payment-methods') as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _methods = (d['methods'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } catch (_) {}
  }

  /// Le serveur calcule distance + frais (aucune valeur n'est décidée par l'app).
  Future<void> _requestQuote(Map<String, dynamic> body, String source) async {
    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    try {
      final d = await context.read<ApiClient>().post('/api/delivery/quote', body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _quote = DeliveryQuote.fromJson(d);
        _quoteSource = source;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _quote = null;
          _quoteError = e.toString();
        });
      }
    }
    if (mounted) setState(() => _quoting = false);
  }

  Future<void> _useGps() async {
    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw 'Active la localisation de ton téléphone.';
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw "Autorisation de localisation refusée. Tu peux saisir ton adresse à la place.";
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await _requestQuote({'lat': pos.latitude, 'lng': pos.longitude}, 'gps');
    } catch (e) {
      if (mounted) {
        setState(() {
          _quoting = false;
          _quoteError = e.toString();
        });
      }
    }
  }

  Future<void> _useAddress() async {
    final a = _address.text.trim();
    if (a.length < 3) {
      setState(() => _quoteError = "Saisis d'abord ton quartier ou un point de repère.");
      return;
    }
    await _requestQuote({'address': a}, 'address');
  }

  Future<void> _order(int expectedTotal) async {
    final cart = context.read<CartProvider>();
    final orders = context.read<OrdersProvider>();
    final menu = context.read<MenuProvider>();
    final nav = context.read<NavController>();

    if (_address.text.trim().isEmpty) return snack(context, 'Indique ton adresse de livraison (quartier, repère).');
    if (_quote == null) return snack(context, 'Active ta position ou valide ton adresse pour calculer la livraison.');

    setState(() => _placing = true);
    try {
      final order = await orders.place({
        'items': cart.toPayload(),
        'address': _address.text.trim(),
        'addressCoords': {'lat': _quote!.lat, 'lng': _quote!.lng},
        'paymentMethod': _payment,
      });
      cart.clear();
      _address.clear();
      setState(() {
        _quote = null;
        _quoteSource = null;
      });
      if (mounted) {
        snack(context, 'Commande ${order.ref} envoyée ✅');
        celebrate(context);
      }
      nav.go(3);
    } on ApiException catch (e) {
      if (e.status == 409) {
        // Un produit est devenu indisponible : on resynchronise le menu et le panier.
        await menu.load();
        final removed = cart.dropUnavailable({for (final p in menu.all) p.id: p});
        if (mounted && removed.isNotEmpty) snack(context, 'Retiré du panier (épuisé) : ${removed.join(', ')}');
      } else if (mounted) {
        snack(context, e.message);
      }
    } catch (e) {
      if (mounted) snack(context, e.toString());
    }
    if (mounted) setState(() => _placing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final promos = context.watch<PromoProvider>();

    if (cart.lines.isEmpty) {
      return EmptyState(
        emoji: '🛍️',
        title: 'Ton panier est vide',
        subtitle: 'Ajoute un shawarma, tu vas te régaler.',
        action: FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(190, 48)),
          onPressed: () => context.read<NavController>().go(0),
          child: const Text('Voir le menu'),
        ),
      );
    }

    final promo = bestPromo(cart.lines, promos.promos, cap: cart.subtotal - cart.loyaltyDiscount);
    final fee = _quote?.fee;
    final total = cart.subtotal - cart.loyaltyDiscount - promo.amount + (fee ?? 0);
    final method = _methods.firstWhere((m) => m['id'] == _payment, orElse: () => {});

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const FadeSlideIn(child: SectionTitle('Mon panier')),
        for (final l in cart.lines)
          Dismissible(
            key: ValueKey(l.key),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              HapticFeedback.mediumImpact();
              cart.remove(l);
            },
            background: Container(
              margin: const EdgeInsets.only(bottom: 8),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 22),
              decoration: BoxDecoration(color: Brand.danger.withOpacity(0.2), borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.delete_outline, color: Brand.danger, size: 28),
            ),
            child: Panel(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              ProductImage(emoji: l.product.emoji, url: l.product.imageUrl, asset: l.product.assetImage, size: 58, radius: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (l.flavor != null) Text('Saveur : ${l.flavor}', style: const TextStyle(color: Brand.dim, fontSize: 12)),
                  if (l.piment != null) Text(l.piment == 'sans' ? 'Sans piment' : '🌶️ Avec piment', style: const TextStyle(color: Brand.dim, fontSize: 12)),
                  Text(fcfa(l.total), style: const TextStyle(color: Brand.gold, fontWeight: FontWeight.w800)),
                ]),
              ),
              IconButton(visualDensity: VisualDensity.compact, onPressed: () => cart.dec(l), icon: const Icon(Icons.remove_circle_outline)),
              Text('${l.qty}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              IconButton(visualDensity: VisualDensity.compact, onPressed: () => cart.inc(l), icon: const Icon(Icons.add_circle_outline, color: Brand.gold)),
            ]),
          ),
          ),
        if (promo.promo != null)
          Panel(
            enterIndex: 0,
            highlight: true,
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const Text('🎉', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Text('${promo.promo!.title} appliquée : -${fcfa(promo.amount)}', style: const TextStyle(fontWeight: FontWeight.w800, color: Brand.gold))),
            ]),
          ),
        if (cart.freeShawarmas > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('🎁 ${cart.freeShawarmas} shawarma(s) offert(s) grâce à ta fidélité !', style: const TextStyle(color: Brand.gold, fontWeight: FontWeight.w800)),
          ),

        const SectionTitle('Livraison'),
        TextField(
          controller: _address,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_quoteSource == 'address') setState(() => _quote = null); // adresse modifiée : à revalider
          },
          decoration: const InputDecoration(labelText: 'Quartier / rue / point de repère', prefixIcon: Icon(Icons.place_outlined)),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _quoting ? null : _useGps,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Ma position'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _quoting ? null : _useAddress,
              icon: const Icon(Icons.search, size: 18),
              label: const Text("Valider l'adresse"),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        if (_quoting) const LinearProgressIndicator(color: Brand.gold, backgroundColor: Brand.line, minHeight: 3),
        if (_quoteError != null)
          Text(_quoteError!, style: const TextStyle(color: Brand.danger, fontWeight: FontWeight.w600)),
        if (_quote != null)
          Panel(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const Icon(Icons.check_circle, color: Brand.ok),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_quote!.km} km · livraison ${fee == 0 ? 'gratuite' : fcfa(fee!)}'
                  '${_quote!.method == 'estimate' ? '  (estimation)' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ]),
          ),

        const SectionTitle('Paiement'),
        for (final m in _methods)
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            activeColor: Brand.gold,
            value: m['id'] as String,
            groupValue: _payment,
            onChanged: (v) => setState(() => _payment = v ?? 'cash'),
            title: Text(m['label'] as String),
          ),
        if (method['depositNumber'] != null)
          Panel(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Envoie ${fcfa(total)} au ${method['depositNumber']} (${method['depositName']}) puis valide ta commande.',
              style: const TextStyle(fontSize: 13),
            ),
          ),

        const SizedBox(height: 6),
        _row('Sous-total', fcfa(cart.subtotal)),
        if (cart.loyaltyDiscount > 0) _row('Fidélité', '- ${fcfa(cart.loyaltyDiscount)}', color: Brand.gold),
        if (promo.amount > 0) _row('Promo', '- ${fcfa(promo.amount)}', color: Brand.gold),
        _row('Livraison', fee == null ? 'à calculer' : (fee == 0 ? 'Gratuite' : fcfa(fee))),
        const Divider(height: 22),
        _totalRow(total),
        const SizedBox(height: 16),
        GoldButton(label: 'Commander · ${fcfa(total)}', busy: _placing, onPressed: () => _order(total)),
        const SizedBox(height: 8),
        const Text('Le serveur recalcule et confirme le total final.', textAlign: TextAlign.center, style: TextStyle(color: Brand.dim, fontSize: 11.5)),
      ],
    );
  }

  Widget _totalRow(int total) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('TOTAL', style: Brand.display(19, spacing: 1)),
          CountUp(value: total, format: fcfa, style: Brand.display(23, color: Brand.gold, spacing: 0.5)),
        ]),
      );

  Widget _row(String a, String b, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500, fontSize: bold ? 18 : 14)),
          Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w700, fontSize: bold ? 18 : 14, color: color ?? (bold ? Brand.gold : null))),
        ]),
      );
}
