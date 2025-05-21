import 'package:flutter/material.dart';
import 'package:hris_mobile_app/config/app_config.dart';
import 'package:hris_mobile_app/screens/dashboard/hris_dashboard.dart';
import 'package:hris_mobile_app/screens/logging/login_screen.dart';
import 'package:hris_mobile_app/screens/logging/register_screen.dart';
import 'package:hris_mobile_app/widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the configuration
  try {
    await AppConfig.initialize();
    print('App config initialized with API URL: ${AppConfig.apiBaseUrl}');
  } catch (e) {
    print('Error initializing app config: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const NavigationExample(),
      },
    );
  }
}
