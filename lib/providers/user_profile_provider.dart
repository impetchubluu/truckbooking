// lib/providers/user_profile_provider.dart
import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';

class UserProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserProfile? _userProfile;
  List<CarProfile> _availableCars = [];
  bool _isLoading = false;
  String? _error;

  // Getters for UI to access data
  UserProfile? get userProfile => _userProfile;
  List<CarProfile> get availableCars => _availableCars;
  bool get isLoading => _isLoading;
  String? get error => _error;
Future<void> fetchUserProfile(String token) async {
    // Only fetch if data isn't already loaded or loading
    if (_userProfile != null || _isLoading) return;

    _isLoading = true;
    _error = null;
    
    // --- THE FIX IS HERE ---
    // Schedule the notification to happen after the build is complete.
    Future.microtask(() => notifyListeners());

    try {
      _userProfile = await _apiService.getUserProfile(token);
      if (_userProfile?.role.toLowerCase() == 'vendor') {
        _availableCars = _userProfile!.cars
            .toList();
      } else {
        _availableCars = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      // This final notifyListeners() is safe because it happens after the 'await'.
      notifyListeners();
    }
  }
   void clear() {
    _userProfile = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
    print("UserProfileProvider cleared!"); // สำหรับ Debug
  }
}