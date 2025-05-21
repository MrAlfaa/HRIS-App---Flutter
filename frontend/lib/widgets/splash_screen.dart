import 'package:flutter/material.dart';
import '../screens/logging/login_screen.dart';
import '../config/app_config.dart';
import '../config/connection_test.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showDebugButton = false;

  @override
  void initState() {
    super.initState();
    _navigateToLogin();

    // For debugging - set to true to show the test connection button
    _showDebugButton = true;
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 4), () {});
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(20.0),
              child: Image.asset(
                'assets/images/splash logo.PNG',
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Debug button for testing connection
          if (_showDebugButton)
            Positioned(
              bottom: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () async {
                  await ConnectionTest.testBackendConnection(context);
                },
                child: const Text('Test Connection'),
              ),
            ),
        ],
      ),
    );
  }
}
