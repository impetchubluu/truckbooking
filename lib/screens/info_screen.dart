import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class InfoScreen extends StatefulWidget {
  final String accessToken;
  final String initialUsername;

  const InfoScreen({
    super.key,
    required this.accessToken,
    required this.initialUsername,
  });

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final ApiService _apiService = ApiService();
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;
  String? _profileError;

  // State Variables for Car Filters
  List<CarProfile> _allCarsForVendor = [];
  List<CarProfile> _filteredCarsForVendor = [];
  final List<String> _carStatOptions = const ['ใช้งาน', 'ไม่ใช้งาน'];
  Set<String> _selectedCarStats = {};
  List<String> _carTypeOptions = [];
  Set<String> _selectedCarTypes = {};

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
      _allCarsForVendor = [];
      _filteredCarsForVendor = [];
      _selectedCarStats = {};
      _selectedCarTypes = {};
      _carTypeOptions = [];
    });

    try {
      final userProfileResult = await _apiService.getUserProfile(widget.accessToken);
      if (!mounted) return;

      setState(() {
        _userProfile = userProfileResult;
        if (_userProfile?.role.toLowerCase() == 'vendor') {
          _allCarsForVendor = List.from(_userProfile!.cars);
          _populateAvailableCarTypes();
          _applyCarFilters();
        } else {
          _clearVendorCarData();
        }
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() {
        _profileError = 'Failed to load profile.';
        _isLoadingProfile = false;
      });
    }
  }

  void _clearVendorCarData() {
    _allCarsForVendor = [];
    _carTypeOptions = [];
    _selectedCarTypes = {};
    _selectedCarStats = {};
    _filteredCarsForVendor = [];
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
    if (_userProfile?.role.toLowerCase() != 'vendor') {
      _filteredCarsForVendor = [];
      return;
    }

    List<CarProfile> tempFiltered = List.from(_allCarsForVendor);
    if (_selectedCarStats.isNotEmpty) {
      tempFiltered = tempFiltered.where((car) => _selectedCarStats.contains(car.stat)).toList();
    }

    if (_selectedCarTypes.isNotEmpty) {
      tempFiltered = tempFiltered.where((car) => _selectedCarTypes.contains(car.cartypedes)).toList();
    }

    setState(() {
      _filteredCarsForVendor = tempFiltered;
    });
  }
void _handleLogout({String? errorMessage}) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  authProvider.logout();  // เรียกใช้ฟังก์ชัน logout ที่คุณประกาศไว้ใน provider
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage ?? 'Logged out successfully!'),
        backgroundColor: errorMessage != null ? Colors.orange.shade800 : Colors.blueGrey,
      ),
    );
  }


}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userProfile?.displayName ?? widget.initialUsername),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          )
        ],
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : _profileError != null
              ? _buildErrorView()
              : _userProfile != null
                  ? _buildProfileView(_userProfile!)
                  : Center(child: Text('No profile data available for ${widget.initialUsername}.')),
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
            Text('Failed to Load Profile', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(_profileError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 20),
            ElevatedButton.icon(icon: const Icon(Icons.refresh_rounded), label: const Text('Retry'), onPressed: _fetchUserDetails),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(UserProfile profile) {
    return RefreshIndicator(
      onRefresh: _fetchUserDetails,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              profile.displayName?.isNotEmpty == true ? profile.displayName![0].toUpperCase() : profile.username[0].toUpperCase(),
              style: TextStyle(fontSize: 40, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName ?? profile.username,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            profile.role.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildFilterSection('Filter by Status:', _carStatOptions, _selectedCarStats, (selected, option) {
            setState(() {
              if (selected) {
                _selectedCarStats.add(option);
              } else {
                _selectedCarStats.remove(option);
              }
              _applyCarFilters();
            });
          }),
          const SizedBox(height: 16),
          _buildFilterSection('Filter by Type:', _carTypeOptions, _selectedCarTypes, (selected, option) {
            setState(() {
              if (selected) {
                _selectedCarTypes.add(option);
              } else {
                _selectedCarTypes.remove(option);
              }
              _applyCarFilters();
            });
          }),
          const Divider(height: 24, thickness: 1),
          _buildCarList(),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options, Set<String> selectedOptions, Function(bool, String) onSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8.0, runSpacing: 4.0,
            children: options.map((option) {
              final bool isSelected = selectedOptions.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (bool selected) => onSelected(selected, option),
                selectedColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                checkmarkColor: Theme.of(context).colorScheme.primary,
                showCheckmark: true,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCarList() {
    if (_filteredCarsForVendor.isEmpty) {
      return const Center(child: Text("No cars match your filter criteria.", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredCarsForVendor.length,
      itemBuilder: (context, index) {
        final car = _filteredCarsForVendor[index];
        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            leading: Icon(
              Icons.directions_car_filled_outlined,
              color: car.stat == "ใช้งาน" ? Theme.of(context).colorScheme.secondary : Colors.grey.shade500,
              size: 36,
            ),
            title: Text(car.carlicense, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(car.cartypedes ?? 'N/A Type'),
          ),
        );
      },
    );
  }
}
