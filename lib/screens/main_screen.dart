import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import 'dispatcher_home_screen.dart';
import 'vendor_home_screen.dart';
import 'booked_screen.dart';
import 'history_screen.dart';
import 'info_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navBarItems = [];
  List<String> _appBarTitles = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _buildUIForRole());
  }
    void _handleLogout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
  }
  void _buildUIForRole() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated || authProvider.userProfile == null) {
      authProvider.logout();
      return;
    }
    final userRole = authProvider.userProfile!.role;
    final token = authProvider.token!;

    if (userRole == 'dispatcher' || userRole == 'admin') {
      setState(() {
        _appBarTitles = ['จัดเตรียมการจอง', 'รายการที่จองแล้ว', 'ประวัติ', 'ขนส่งของฉัน'];
        _pages = [
          DispatcherHomeScreen(accessToken: token),
          const BookedScreen(),
          const HistoryScreen(),
          const InfoScreen(),
        ];
        _navBarItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.home_work_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_rounded), label: 'Booked'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Info'),
        ];
      });
    } else if (userRole == 'vendor') {
      setState(() {
        _appBarTitles = ['งานใหม่', 'งานที่รับแล้ว', 'ประวัติ', 'ข้อมูลของฉัน'];
        _pages = [
          const VendorHomeScreen(),
          const BookedScreen(),
          const HistoryScreen(),
          const InfoScreen(),
        ];
        _navBarItems = const [
          BottomNavigationBarItem(icon: Icon(Icons.new_releases_rounded), label: 'New Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.check_box_rounded), label: 'My Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'My Info'),
        ];
      });
    } else {
      setState(() {
        _appBarTitles = ["Error"];
        _pages = [Center(child: Text("Error: Unknown user role: '$userRole'"))];
        _navBarItems = [const BottomNavigationBarItem(icon: Icon(Icons.error), label: 'Error')];
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles.isNotEmpty ? _appBarTitles[_selectedIndex] : 'Loading...'),
        actions: [
          IconButton(
            icon:  const Icon(Icons.logout),
            onPressed: () {
              _handleLogout();
            },
          )
        ],
      ),
      body: _pages.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : IndexedStack(index: _selectedIndex, children: _pages),
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