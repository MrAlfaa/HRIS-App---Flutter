import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AppConfig {
  // API Base URL configurations - NO SPACES in URLs
  static const String localEmulatorUrl = 'http://10.0.2.2:8080';
  static const String localSimulatorUrl = 'http://localhost:8080';
  // Update this to your computer's actual IP address on your local network
  static const String localNetworkUrl = 'http://192.168.53.175:8080';

  // Fallback URL when others fail
  static const String fallbackUrl = 'http://localhost:8080';

  // Default API URL (more reliable default)
  static String _apiBaseUrl = fallbackUrl;

  // Getter for apiBaseUrl
  static String get apiBaseUrl => _apiBaseUrl;

  // API endpoints
  static String get loginEndpoint => '$_apiBaseUrl/login';
  static String get registerEndpoint => '$_apiBaseUrl/register';
  static String get apiStatusEndpoint => '$_apiBaseUrl/api/status';

  // Initialize the config
  static Future<void> initialize() async {
    if (kIsWeb) {
      // For web, use whatever URL is appropriate for your deployment
      _apiBaseUrl = fallbackUrl;
      return;
    }

    List<String> urlsToTry = [];

    // For physical devices, prioritize the network URL
    if (Platform.isAndroid && !isPhysicalDevice()) {
      // Emulator
      urlsToTry = [localEmulatorUrl, localNetworkUrl, fallbackUrl];
    } else if (Platform.isIOS && !isPhysicalDevice()) {
      // Simulator
      urlsToTry = [localSimulatorUrl, localNetworkUrl, fallbackUrl];
    } else {
      // Physical devices or desktop - prioritize network URL
      urlsToTry = [localNetworkUrl, fallbackUrl];
    }

    bool connected = false;
    for (String url in urlsToTry) {
      try {
        final testUrl = '$url/api/status';
        print('Trying to connect to: $testUrl');
        final response = await http
            .get(Uri.parse(testUrl))
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          _apiBaseUrl = url;
          print('Successfully connected to API at: $_apiBaseUrl');
          connected = true;
          break;
        }
      } catch (e) {
        print('Failed to connect to API at: $url - Error: $e');
      }
    }

    if (!connected) {
      // For physical devices, default to the network URL if no connection
      if (isPhysicalDevice()) {
        _apiBaseUrl = localNetworkUrl;
        print('Using physical device default: $_apiBaseUrl');
      } else {
        print(
            'Warning: Could not connect to any API endpoint. Using default: $_apiBaseUrl');
      }
    }
  }

  // Helper method to check if the app is running on a physical device
  static bool isPhysicalDevice() {
    if (kIsWeb) return false;
    try {
      // This is a best-guess approach - not perfect but helps for most cases
      if (Platform.isAndroid || Platform.isIOS) {
        // Real devices tend to have different screen sizes than emulators
        // We could enhance this with device info plugin for better detection
        return true; // For now, always assume physical for safety
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
