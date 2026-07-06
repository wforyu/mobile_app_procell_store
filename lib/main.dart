import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: ApiService().hasToken
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
