// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart'; // Import ApiService ของคุณ

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  Future<void> initialize() async {
    // ขอ Permission (สำคัญมากสำหรับ iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      // ดึง Token และลงทะเบียนกับ Backend
      // เราจะทำขั้นตอนนี้หลังจาก User Login สำเร็จ
    } else {
      print('User declined or has not accepted permission');
    }

    // Handle incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the FOREGROUND!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // TODO: แสดง Local Notification หรืออัปเดต UI ถ้าต้องการ
      }
    });
  }

  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print("Firebase Messaging Token: $token");
      return token;
    } catch (e) {
      print("Failed to get FCM token: $e");
      return null;
    }
  }

  Future<void> registerTokenWithBackend(String userAccessToken, String fcmToken) async {
    try {
      print("Attempting to register FCM token with backend...");
      // สร้างฟังก์ชันนี้ใน ApiService ของคุณ
      await _apiService.updateFCMToken(userAccessToken, fcmToken);
      print("FCM token registration with backend successful.");
    } catch (e) {
      print("Failed to register FCM token with backend: $e");
    }
  }
}