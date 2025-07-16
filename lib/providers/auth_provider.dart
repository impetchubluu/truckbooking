import 'dart:convert'; // เพิ่มการใช้งาน jsonEncode และ jsonDecode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  AuthProvider() {
    _loadFromPrefs();  // โหลดข้อมูลจาก shared_preferences
  }

  // โหลดข้อมูลจาก shared_preferences
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    // ตรวจสอบว่าเรามี userProfile ที่เก็บเป็น String แล้วแปลงกลับเป็น UserProfile
    String? userProfileString = prefs.getString('userProfile');
    if (userProfileString != null) {
      // ใช้ jsonDecode เพื่อแปลงเป็น Map แล้วสร้าง UserProfile
      _userProfile = UserProfile.fromJson(jsonDecode(userProfileString));
    }

    notifyListeners();
  }

  // ฟังก์ชันสำหรับการล็อกอิน
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    final result = await _authService.login(username, password);

    if (result['success'] == true && result['data']?['access_token'] != null) {
      _token = result['data']['access_token'];
      await fetchUserProfile(); // Fetch profile right after getting token
      if (_authError == null) {
        // VVVVVV ส่วนที่เพิ่มเข้ามา VVVVVV
        // หลังจาก Login และ Fetch Profile สำเร็จแล้ว ให้ดึง FCM Token และส่งไป Backend
        final fcmToken = await _notificationService.getFCMToken();
        if (fcmToken != null) {
          await _notificationService.registerTokenWithBackend(_token!, fcmToken);
        }
        // เก็บข้อมูลที่ล็อกอินลง shared_preferences
        await _saveToPrefs();
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

  // ฟังก์ชันสำหรับดึงข้อมูลโปรไฟล์ผู้ใช้
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

  // ฟังก์ชันสำหรับการออกจากระบบ
  void logout() {
    _token = null;
    _userProfile = null;
    _clearPrefs(); // ลบข้อมูลจาก shared_preferences
    print("AuthProvider: User logged out.");
    notifyListeners();
  }

  // ลบข้อมูลออกจาก shared_preferences
  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userProfile');
  }

  // ฟังก์ชันสำหรับการเก็บข้อมูลลง shared_preferences
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('token', _token!);
    }
    if (_userProfile != null) {
      // ใช้ jsonEncode เพื่อแปลง UserProfile เป็น String และเก็บใน shared_preferences
      await prefs.setString('userProfile', jsonEncode(_userProfile!.toJson()));
    }
  }
}
