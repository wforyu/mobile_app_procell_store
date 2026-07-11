import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'helpers/theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  await api.init();

  // Auto-logout saat token expired (401)
  api.setOnUnauthenticated(() {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Sesi berakhir. Silakan login ulang.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  });

  runApp(const ProcellApp());
}

class ProcellApp extends StatelessWidget {
  const ProcellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProCell Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}
