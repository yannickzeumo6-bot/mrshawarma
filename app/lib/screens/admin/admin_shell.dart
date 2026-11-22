import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/push_service.dart';
import '../../widgets/fx.dart';
import 'admin_menu_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_promos_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    PushService.instance.registerDevice(context.read<ApiClient>()); // alertes « nouvelle commande »
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final auth = context.read<AuthProvider>();
    final pending = admin.orders.where((o) => o.status == 'received').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN · MR. SHAWARMA', style: TextStyle(fontWeight: FontWeight.w900, color: Brand.gold, letterSpacing: 1, fontSize: 17)),
        actions: [
          IconButton(onPressed: admin.refreshAll, icon: const Icon(Icons.refresh)),
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
      body: FadeIndexedStack(index: _tab, children: const [AdminOrdersScreen(), AdminMenuScreen(), AdminPromosScreen()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: Pop(trigger: pending, child: Badge(isLabelVisible: pending > 0, label: Text('$pending'), child: const Icon(Icons.receipt_long_outlined))),
            label: 'Commandes',
          ),
          const NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
          const NavigationDestination(icon: Icon(Icons.local_offer_outlined), label: 'Promotions'),
        ],
      ),
    );
  }
}
