import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;


class AuthService {
  static const String _androidEmulatorBaseUrl = "http://10.0.2.2:5000";
  static const String _iosSimulatorDesktopBaseUrl = "http://localhost:5000";
  static const String _webBaseUrl = "http://localhost:5000";

  String get baseUrl {
    if (kIsWeb) {
      print("INFO: Running on Web, using base URL: $_webBaseUrl");
      return _webBaseUrl;
    }
    if (Platform.isAndroid) {
      print("INFO: Running on Android, using base URL: $_androidEmulatorBaseUrl");
      return _androidEmulatorBaseUrl;
    }
    if (Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      print("INFO: Running on iOS/Desktop, using base URL: $_iosSimulatorDesktopBaseUrl");
      return _iosSimulatorDesktopBaseUrl;
    }
    print("INFO: Unknown platform, defaulting to base URL: $_iosSimulatorDesktopBaseUrl");
    return _iosSimulatorDesktopBaseUrl;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final String apiUrl = "$baseUrl/auth/login";
    print('AuthService: Attempting to login to: $apiUrl');
  
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      ).timeout(const Duration(seconds: 15));

      final responseData = json.decode(response.body);
      print('AuthService: Login Response Status: ${response.statusCode}');
      print('AuthService: Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        
     
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'error': responseData['detail'] ?? 'Login failed (Status: ${response.statusCode})'};
      }
      
    } catch (e) {
      print('AuthService: Login Exception: $e');
      return {'success': false, 'error': 'Could not connect to server. Please check your connection.'};
    }
  }
}