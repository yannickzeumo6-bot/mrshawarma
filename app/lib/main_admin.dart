import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/phone_frame.dart';
import 'core/theme.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/shared/login_screen.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';
import 'services/push_service.dart';
import 'widgets/fx.dart';

/// Application ADMIN.  flutter run --flavor admin -t lib/main_admin.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await NotificationService.instance.init();
    await PushService.instance.init();
  }
  final api = ApiClient();
  final auth = AuthProvider(api, role: 'admin');
  await auth.restore();
  runApp(AdminApp(api: api, auth: auth));
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.api, required this.auth});
  final ApiClient api;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          title: 'Mr. Shawarma Admin',
          debugShowCheckedModeBanner: false,
          theme: Brand.theme(),
          builder: (context, child) => PhoneFrame(child: child ?? const SizedBox()),
          home: const SplashGate(subtitle: 'ADMINISTRATION', child: _Root()),
        ),
      );
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const LoginScreen(role: 'admin');
    final api = context.read<ApiClient>();
    return ChangeNotifierProvider(
      key: ValueKey(auth.user!.id),
      create: (_) => AdminProvider(api),
      child: const AdminShell(),
    );
  }
}
