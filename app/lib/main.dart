import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/phone_frame.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/nav_controller.dart';
import 'providers/orders_provider.dart';
import 'providers/promo_provider.dart';
import 'screens/client/home_shell.dart';
import 'screens/shared/login_screen.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';
import 'services/push_service.dart';
import 'widgets/fx.dart';

/// Application CLIENT.  flutter run --flavor client -t lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await PushService.instance.init();
  final api = ApiClient();
  final auth = AuthProvider(api, role: 'client');
  await auth.restore();
  runApp(ClientApp(api: api, auth: auth));
}

class ClientApp extends StatelessWidget {
  const ClientApp({super.key, required this.api, required this.auth});
  final ApiClient api;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          title: 'Mr. Shawarma',
          debugShowCheckedModeBanner: false,
          theme: Brand.theme(),
          builder: (context, child) => PhoneFrame(child: child ?? const SizedBox()),
          home: const SplashGate(child: _Root()),
        ),
      );
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const LoginScreen(role: 'client');
    final api = context.read<ApiClient>();
    // Clé = id utilisateur : panier, commandes... sont recréés à chaque changement de compte.
    return MultiProvider(
      key: ValueKey(auth.user!.id),
      providers: [
        ChangeNotifierProvider(create: (_) => MenuProvider(api)),
        ChangeNotifierProvider(create: (_) => PromoProvider(api)),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider(api)),
        ChangeNotifierProvider(create: (_) => NavController()),
      ],
      child: const HomeShell(),
    );
  }
}
