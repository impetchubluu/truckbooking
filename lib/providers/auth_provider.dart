import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
class AuthProvider with ChangeNotifier {
  String? _token;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _authError;

  String? get token => _token;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get authError => _authError;
  bool get isAuthenticated => _token != null && _userProfile != null;

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    final result = await _authService.login(username, password);

    if (result['success'] == true && result['data']?['access_token'] != null) {
      _token = result['data']['access_token'];
      await fetchUserProfile(); // Fetch profile right after getting token
       if (_authError == null) { // ถ้า fetchUserProfile สำเร็จ
        // VVVVVV ส่วนที่เพิ่มเข้ามา VVVVVV
        // หลังจาก Login และ Fetch Profile สำเร็จแล้ว ให้ดึง FCM Token และส่งไป Backend
        final fcmToken = await _notificationService.getFCMToken();
        if (fcmToken != null) {
          await _notificationService.registerTokenWithBackend(_token!, fcmToken);
        }
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        _isLoading = false;
        notifyListeners();
        return true;
      }
    }

    _authError = result['error']?.toString() ?? 'Login failed.';
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchUserProfile() async {
    if (_token == null) return;
    try {
      final profile = await _apiService.getUserProfile(_token!);
      _userProfile = profile;
      _authError = null;
    } catch (e) {
      final errorResult = e as Map<String, dynamic>? ?? {};
      _authError = errorResult['error']?.toString() ?? "Failed to fetch user profile.";
      if (errorResult['isAuthError'] == true) {
        logout(); // Logout if token is invalid/expired
      }
    }
  }

  void logout() {
    _token = null;
    _userProfile = null;
    // TODO: Clear token from secure storage
    print("AuthProvider: User logged out.");
    notifyListeners();
  }
}