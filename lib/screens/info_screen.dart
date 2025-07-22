// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class InfoScreen extends StatefulWidget {
  // ไม่จำเป็นต้องรับ accessToken และ initialUsername มาอีกแล้ว
  // เพราะเราจะดึงจาก AuthProvider โดยตรง
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;

  // --- State สำหรับ Vendor ---
  UserProfile? _vendorProfile;
  List<CarProfile> _allCarsForVendor = [];
  List<CarProfile> _filteredCarsForVendor = [];
  final List<String> _carStatOptions = const ['ใช้งาน', 'ไม่ใช้งาน'];
  Set<String> _selectedCarStats = {};
  List<String> _carTypeOptions = [];
  Set<String> _selectedCarTypes = {};

  // --- State สำหรับ Admin/Dispatcher ---
  List<VendorProfile> _allVendors = [];
  List<VendorProfile> _filteredVendors = [];
  final List<String> _gradeOptions = const ['A', 'B', 'C', 'D'];
  Set<String> _selectedGrades = {};

  @override
  void initState() {
    super.initState();
    // ใช้ Future.microtask เพื่อให้ Provider พร้อมใช้งานก่อน
    Future.microtask(() => _fetchDataForRole());
  }

  Future<void> _fetchDataForRole() async {
    setState(() { _isLoading = true; _error = null; });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userRole = authProvider.userProfile?.role;

    if (token == null) {
      setState(() { _error = "Authentication error."; _isLoading = false; });
      return;
    }
    
    try {
      if (userRole == 'vendor') {
        await _fetchVendorDetails(token);
      } else if (userRole == 'admin' || userRole == 'dispatcher') {
        await _fetchAllVendors(token);
      } else {
        throw Exception("Unknown user role: $userRole");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
    } finally {
      if (!mounted) return;
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _fetchVendorDetails(String token) async {
    final userProfileResult = await _apiService.getUserProfile(token);
    if (!mounted) return;

    _vendorProfile = userProfileResult;
    _allCarsForVendor = List.from(_vendorProfile!.cars);
    _populateAvailableCarTypes();
    _applyCarFilters(); // กรองครั้งแรก
  }
  
  Future<void> _fetchAllVendors(String token) async {
    final vendorsResult = await _apiService.getAllVendorProfiles(token);
    if (!mounted) return;
    
    _allVendors = vendorsResult;
    _applyVendorGradeFilter(); // กรองครั้งแรก
  }

  void _populateAvailableCarTypes() {
    final carTypeDescriptions = _allCarsForVendor
        .map((car) => car.cartypedes)
        .whereType<String>()
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList();
    carTypeDescriptions.sort();
    _carTypeOptions = carTypeDescriptions;
  }

  void _applyCarFilters() {
    List<CarProfile> tempFiltered = List.from(_allCarsForVendor);
    if (_selectedCarStats.isNotEmpty) {
      tempFiltered = tempFiltered.where((car) => _selectedCarStats.contains(car.stat)).toList();
    }
    if (_selectedCarTypes.isNotEmpty) {
      tempFiltered = tempFiltered.where((car) => _selectedCarTypes.contains(car.cartypedes)).toList();
    }
    _filteredCarsForVendor = tempFiltered;
  }
  
  void _applyVendorGradeFilter() {
    if (_selectedGrades.isEmpty) {
      _filteredVendors = List.from(_allVendors);
    } else {
      _filteredVendors = _allVendors.where((vendor) => _selectedGrades.contains(vendor.grade)).toList();
    }
    // ไม่ต้องมี setState ที่นี่ เพราะจะถูกเรียกใช้ใน context ที่มี setState อยู่แล้ว
  }

  void _handleLogout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
  }

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลจาก Provider เพื่อใช้ใน UI
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.userProfile?.role;
    final displayName = authProvider.userProfile?.displayName ?? authProvider.userProfile?.username ?? 'User';
    
    return Scaffold(
      // AppBar จะถูกจัดการโดย MainScreen.dart อยู่แล้ว จึงไม่จำเป็นต้องมีที่นี่
      // แต่ถ้าหน้านี้เป็นหน้าเดี่ยวๆ ก็ใส่ AppBar ไว้ได้
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _fetchDataForRole,
                  child: (userRole == 'vendor')
                      ? _buildVendorProfileView(authProvider.userProfile!)
                      : _buildAdminVendorListView(),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 60),
            const SizedBox(height: 16),
            const Text('Failed to Load Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 20),
            ElevatedButton.icon(icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'), onPressed: _fetchDataForRole),
          ],
        ),
      ),
    );
  }

  // --- UI View สำหรับ Vendor ---
  Widget _buildVendorProfileView(UserProfile profile) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        _buildProfileHeader(profile.displayName, profile.username, profile.role),
        const SizedBox(height: 24),
        _buildFilterSection('Filter by Status:', _carStatOptions, _selectedCarStats, (selected, option) {
          setState(() {
            if (selected) { _selectedCarStats.add(option); } 
            else { _selectedCarStats.remove(option); }
            _applyCarFilters();
          });
        }),
        const SizedBox(height: 16),
        _buildFilterSection('Filter by Type:', _carTypeOptions, _selectedCarTypes, (selected, option) {
          setState(() {
            if (selected) { _selectedCarTypes.add(option); }
            else { _selectedCarTypes.remove(option); }
            _applyCarFilters();
          });
        }),
        const Divider(height: 24, thickness: 1),
        const Text("My Vehicles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildCarList(),
      ],
    );
  }

  // --- UI View สำหรับ Admin/Dispatcher ---
  Widget _buildAdminVendorListView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildFilterSection('Filter by Grade:', _gradeOptions, _selectedGrades, (selected, option) {
            setState(() {
              if (selected) { _selectedGrades.add(option); } 
              else { _selectedGrades.remove(option); }
              _applyVendorGradeFilter();
            });
          }),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: _filteredVendors.isEmpty
            ? const Center(child: Text("No vendors match your filter."))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _filteredVendors.length,
                itemBuilder: (context, index) {
                  final vendor = _filteredVendors[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ExpansionTile(
                      leading: CircleAvatar(child: Text(vendor.grade)),
                      title: Text(vendor.venname, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${vendor.cars.length} vehicles'),
                      children: vendor.cars.isEmpty 
                        ? [const ListTile(title: Text("No vehicles registered.", style: TextStyle(fontStyle: FontStyle.italic)))]
                        : vendor.cars.map((car) => ListTile(
                            title: Text(car.carlicense),
                            subtitle: Text(car.cartypedes ?? 'N/A'),
                            dense: true,
                            trailing: Text(car.stat, style: TextStyle(color: car.stat == 'ใช้งาน' ? Colors.green : Colors.red)),
                          )).toList(),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
  
  // --- Reusable Widgets ---
  
  Widget _buildProfileHeader(String? displayName, String username, String role) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            displayName?.isNotEmpty == true ? displayName![0].toUpperCase() : username[0].toUpperCase(),
            style: TextStyle(fontSize: 40, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName ?? username,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(
          role.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilterSection(String title, List<String> options, Set<String> selectedOptions, Function(bool, String) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        if (options.isEmpty)
          const Text("No options available.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
        else
          Wrap(
            spacing: 8.0, runSpacing: 4.0,
            children: options.map((option) {
              return FilterChip(
                label: Text(option),
                selected: selectedOptions.contains(option),
                onSelected: (bool selected) => onSelected(selected, option),
                selectedColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCarList() {
    if (_filteredCarsForVendor.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text("No cars match your filter criteria.", style: TextStyle(color: Colors.grey))),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredCarsForVendor.length,
      itemBuilder: (context, index) {
        final car = _filteredCarsForVendor[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Icon(
              Icons.directions_car_filled_outlined,
              color: car.stat == "ใช้งาน" ? Theme.of(context).colorScheme.secondary : Colors.grey.shade500,
            ),
            title: Text(car.carlicense, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(car.cartypedes ?? 'N/A Type'),
            trailing: Text(car.stat, style: TextStyle(color: car.stat == 'ใช้งาน' ? Colors.green : Colors.red)),
          ),
        );
      },
    );
  }
}