import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/phone_frame.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/livreur_provider.dart';
import 'screens/livreur/livreur_shell.dart';
import 'screens/shared/login_screen.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';
import 'services/push_service.dart';
import 'widgets/fx.dart';

/// Application LIVREUR.  flutter run -t lib/main_livreur.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await PushService.instance.init();
  final api = ApiClient();
  final auth = AuthProvider(api, role: 'livreur');
  await auth.restore();
  runApp(LivreurApp(api: api, auth: auth));
}

class LivreurApp extends StatelessWidget {
  const LivreurApp({super.key, required this.api, required this.auth});
  final ApiClient api;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          title: 'Mr. Shawarma Livreur',
          debugShowCheckedModeBanner: false,
          theme: Brand.theme(),
          builder: (context, child) => PhoneFrame(child: child ?? const SizedBox()),
          home: const SplashGate(subtitle: 'LIVREUR', travel: '🛵', child: _Root()),
        ),
      );
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const LoginScreen(role: 'livreur');
    final api = context.read<ApiClient>();
    return ChangeNotifierProvider(
      key: ValueKey(auth.user!.id),
      create: (_) => LivreurProvider(api),
      child: const LivreurShell(),
    );
  }
}
