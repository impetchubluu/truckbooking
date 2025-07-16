import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("--- Background Message Received ---");
  print("Message ID: ${message.messageId}");
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationService().initialize();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truck Booking App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // ตั้งค่าสีหลักของแอปให้ใกล้เคียงกับสีในดีไซน์
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF404E88)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade100, // สีพื้นหลังทั่วไป (ไม่ใช่หน้า Login)
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF404E88), // สี AppBar
          foregroundColor: Colors.white, // สีตัวอักษรและไอคอนบน AppBar
          elevation: 2,
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Logic นี้จะสลับหน้าให้อัตโนมัติเมื่อสถานะการ Login เปลี่ยน
          if (auth.isAuthenticated) {
            return const MainScreen(); // ถ้า Login แล้ว -> ไปหน้าหลักที่มี Bottom Nav
          } else {
            return const LoginScreen(); // ถ้ายังไม่ Login -> ไปหน้า Login
          }
        },
      ),
    );
  }
}