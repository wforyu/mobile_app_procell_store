import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'helpers/theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
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
