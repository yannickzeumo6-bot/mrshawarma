import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/nav_controller.dart';
import '../../providers/promo_provider.dart';
import '../../services/api_client.dart';
import '../../services/push_service.dart';
import '../../widgets/fx.dart';
import 'cart_screen.dart';
import 'menu_screen.dart';
import 'orders_screen.dart';
import 'promotions_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  @override
  void initState() {
    super.initState();
    // Notifications push : promos (sujet) + commandes (appareil lié au compte).
    final api = context.read<ApiClient>();
    PushService.instance.subscribePromos();
    PushService.instance.registerDevice(api);
    // Comptes créés avant l'ajout du téléphone : on demande le numéro (le livreur pourra appeler).
    WidgetsBinding.instance.addPostFrameCallback((_) => _askPhone());
  }

  Future<void> _askPhone() async {
    final auth = context.read<AuthProvider>();
    if (!mounted || auth.user == null || auth.user!.phone != null) return;
    final ctrl = TextEditingController();
    String? err;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Brand.surface,
          title: const Text('Ton numéro de téléphone'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ton livreur pourra t\'appeler pour la livraison.', style: TextStyle(color: Brand.dim)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Téléphone', hintText: '6 90 00 00 00'),
            ),
            if (err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: const TextStyle(color: Brand.danger))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Plus tard')),
            TextButton(
              onPressed: () async {
                try {
                  await auth.updatePhone(ctrl.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  setS(() => err = e.toString());
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    final promo = context.watch<PromoProvider>();
    final cart = context.watch<CartProvider>();
    final auth = context.read<AuthProvider>();

    if (nav.index == 1 && promo.unreadCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => promo.markAllRead());
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/logo.png', width: 32, height: 32),
          const SizedBox(width: 9),
          Text('MR. SHAWARMA', style: Brand.display(21, color: Brand.gold, spacing: 1)),
        ]),
        actions: [
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
      body: FadeIndexedStack(
        index: nav.index,
        children: const [MenuScreen(), PromotionsScreen(), CartScreen(), OrdersScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: nav.index,
        onDestinationSelected: nav.go,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          NavigationDestination(
            icon: Pop(
              trigger: promo.unreadCount,
              child: Badge(
                isLabelVisible: promo.unreadCount > 0,
                label: Text('${promo.unreadCount}'),
                child: const Icon(Icons.local_offer_outlined),
              ),
            ),
            label: 'Promos',
          ),
          NavigationDestination(
            icon: Pop(
              trigger: cart.count,
              child: Badge(
                isLabelVisible: cart.count > 0,
                label: Text('${cart.count}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
            label: 'Panier',
          ),
          const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Commandes'),
        ],
      ),
    );
  }
}
