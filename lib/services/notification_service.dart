// ในไฟล์ lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart'; // สำหรับ kDebugMode

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService(); // สมมติว่ามี ApiService

  Future<void> initialize() async {
    // 1. ขอ Permission
    await _requestPermission();

    // 2. จัดการข้อความตอนแอปอยู่ Foreground
    _setupForegroundMessageHandler();

    // 3. จัดการเมื่อผู้ใช้กดที่ Notification เพื่อเปิดแอป
    _setupInteractionHandler();
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      } else {
        print('User declined or has not accepted permission');
      }
    }
  }

  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('--- Foreground Message Received ---');
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print('Message notification: ${message.notification}');
          // ถ้าต้องการให้แสดง popup ตอนแอปเปิดอยู่
          // ต้องใช้ local notification plugin
        }
      }
    });
  }
  
  void _setupInteractionHandler() {
    // เมื่อแอปถูกเปิดจากสถานะ Terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        // ทำอะไรบางอย่างเมื่อเปิดแอปจาก notification ที่ถูกปิดไปแล้ว
        if (kDebugMode) print("Opened from terminated state: ${message.data}");
      }
    });

    // เมื่อแอปอยู่ใน Background และผู้ใช้กด
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // ทำอะไรบางอย่างเมื่อเปิดแอปจาก background
      if (kDebugMode) print("Opened from background state: ${message.data}");
    });
  }

  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (kDebugMode) print("LATEST FCM  Token: $token");
      return token;
    } catch (e) {
      if (kDebugMode) print("Failed to get FCM token: $e");
      return null;
    }
  }

  Future<void> registerTokenWithBackend(String userAccessToken, String fcmToken) async {
    // โค้ดส่วนนี้ของคุณถูกต้องแล้ว
    try {
      print("Attempting to register FCM token with backend...");
      await _apiService.updateFCMToken(userAccessToken, fcmToken);
      print("FCM token registration with backend successful.");
    } catch (e) {
      print("Failed to register FCM token with backend: $e");
    }
  }
}