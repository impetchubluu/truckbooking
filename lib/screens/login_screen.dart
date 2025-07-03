import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _performLogin() async {
    // ซ่อน Keyboard เมื่อกดปุ่ม
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Provider จะจัดการเรื่อง Loading State และการ Navigate ผ่าน Consumer ใน main.dart
      await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // กำหนดค่าสีตามดีไซน์
    const primaryColor = Color.fromARGB(255, 28, 63, 205);
    const accentColor = Color(0xFFE0E0E0); // สีพื้นหลังของช่องกรอก
    const textColor = Color(0xFFD1D9FF); // สีตัวอักษรและไอคอน

    return Scaffold(
      backgroundColor: primaryColor, // ตั้งค่าสีพื้นหลังหลัก
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Consumer<AuthProvider>(
              builder: (context, auth, child) {
                // แสดง Error Message ถ้ามี
                if (auth.authError != null && !auth.isLoading) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(auth.authError!),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  });
                }
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- Logo Section ---
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined, // ไอคอนรถบรรทุก
                        size: 80,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Truck Booking',
                      style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w500),
                    ),
                    const Text(
                      'Thai City Electric',
                      style: TextStyle(color: textColor, fontSize: 18),
                    ),
                    const SizedBox(height: 40),

                    // --- Login Form ---
                    Text(
                      'Login',
                      style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // -- Username Field --
                          Row(
                            children: [
                              Icon(Icons.person_outline, color: textColor, size: 20),
                              SizedBox(width: 8),
                              Text('Username', style: TextStyle(color: textColor, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: accentColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            keyboardType: TextInputType.text,
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter your username' : null,
                          ),
                          const SizedBox(height: 20),

                          // -- Password Field --
                          Row(
                            children: [
                              Icon(Icons.lock_outline, color: textColor, size: 20),
                              SizedBox(width: 8),
                              Text('Password', style: TextStyle(color: textColor, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: accentColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            obscureText: true,
                            validator: (value) => (value == null || value.isEmpty) ? 'Please enter your password' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- Login Button ---
                    auth.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _performLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white, // สีปุ่ม
                                foregroundColor: primaryColor, // สีตัวอักษรบนปุ่ม
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                    const SizedBox(height: 40),

                    // --- Help Link ---
                    TextButton(
                      onPressed: () {
                        // TODO: Implement Help logic or navigation
                      },
                      child: Text(
                        'Help',
                        style: TextStyle(color: textColor.withOpacity(0.8)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}