// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truck_booking_app/providers/auth_provider.dart';
import 'package:truck_booking_app/screens/booked_screen.dart';
import 'package:truck_booking_app/screens/dispatcher_home_screen.dart';
import 'package:truck_booking_app/screens/history_screen.dart';
import 'package:truck_booking_app/screens/info_screen.dart';
import 'package:truck_booking_app/screens/mybooking_screen.dart';
import 'package:truck_booking_app/screens/vendor_home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  // --- ลบ List<Widget> _pages = []; ออกไปจากตรงนี้ ---

  // --- ส่วนของ NavBarItems และ Titles ยังคงเหมือนเดิม ---
  List<BottomNavigationBarItem> _navBarItems = [];
  List<String> _appBarTitles = [];

  @override
  void initState() {
    super.initState();
    // initState จะทำหน้าที่แค่สร้าง NavBar และ Titles (ไม่ต้องสร้าง Pages)
    _buildNavItemsAndTitlesForRole();
  }

  // สร้างฟังก์ชันใหม่สำหรับจัดการ UI (แยกออกจาก build)
  void _buildNavItemsAndTitlesForRole() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.userProfile == null) {
      authProvider.logout();
      return;
    }
    final userRole = authProvider.userProfile!.role;

    if (userRole == 'dispatcher' || userRole == 'admin') {
      _appBarTitles = ['จัดเตรียมการจอง', 'รายการที่จองแล้ว', 'ประวัติ', 'ขนส่งของฉัน'];
      _navBarItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home_work_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.local_shipping_rounded), label: 'Booked'),
        BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Info'),
      ];
    } else if (userRole == 'vendor') {
      _appBarTitles = ['งานใหม่', 'งานที่รับแล้ว', 'ประวัติ', 'ข้อมูลของฉัน'];
      _navBarItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.new_releases_rounded), label: 'New Jobs'),
        BottomNavigationBarItem(icon: Icon(Icons.check_box_rounded), label: 'My Bookings'),
        BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'My Info'),
      ];
    } else {
      _appBarTitles = ["Error"];
      _navBarItems = [const BottomNavigationBarItem(icon: Icon(Icons.error), label: 'Error')];
    }
    // ใช้ setState ที่นี่เพื่อให้ UI ของ AppBar และ BottomNav อัปเดตหลัง initState
    setState(() {});
  }
  
  void _handleLogout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
  }

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
  }

  // --- [จุดแก้ไขที่ 1] สร้างฟังก์ชันสำหรับสร้าง Pages ---
  List<Widget> _buildPagesForRole() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.userProfile == null) {
      return [const Center(child: CircularProgressIndicator())]; // หน้าจอชั่วคราว
    }
    final userRole = authProvider.userProfile!.role;
    final token = authProvider.token!;

    if (userRole == 'dispatcher' || userRole == 'admin') {
      return [
        DispatcherHomeScreen(accessToken: token),
        const BookedScreen(),
        const HistoryScreen(),
        const InfoScreen(),
      ];
    } else if (userRole == 'vendor') {
      return [
        const VendorHomeScreen(),
        const MyBooking(),
        const HistoryScreen(),
        const InfoScreen(),
      ];
    } else {
      return [Center(child: Text("Error: Unknown user role: '$userRole'"))];
    }
  }


  @override
  Widget build(BuildContext context) {
    // --- [จุดแก้ไขที่ 2] เรียกใช้ฟังก์ชันสร้าง Pages ที่นี่ ---
    final pages = _buildPagesForRole();

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles.isNotEmpty ? _appBarTitles[_selectedIndex] : 'Loading...'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          )
        ],
      ),
      // --- [จุดแก้ไขที่ 3] เปลี่ยน body ---
      body: pages.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : pages[_selectedIndex], // <-- ไม่ใช้ IndexedStack
      
      bottomNavigationBar: _navBarItems.isEmpty
        ? const SizedBox.shrink()
        : BottomNavigationBar(
            items: _navBarItems,
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey.shade600,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
          ),
    );
  }
}