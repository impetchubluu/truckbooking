// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/api_models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  List<Shipment> _history = [];
  bool _isLoading = true;
  String? _error;
  
  // State สำหรับ Filter ของ Admin/Dispatcher
  final TextEditingController _shipmentIdController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  bool _isFilterPanelExpanded = false; 
  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }
  @override
  void dispose() {
    _shipmentIdController.dispose();
    _routeController.dispose();
    super.dispose();
  }
  Future<void> _pickDateRange() async {
  final initialDateRange = _selectedDateRange ??
      DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      );

  final newDateRange = await showDateRangePicker(
    context: context,
    firstDate: DateTime(DateTime.now().year - 1), // ย้อนหลังได้ 1 ปี
    lastDate: DateTime.now(),
    initialDateRange: initialDateRange,
  );

  if (newDateRange != null) {
    setState(() {
      _selectedDateRange = newDateRange;
    });
  }
}
  Future<void> _fetchHistory({Map<String, String>? filters}) async {
    setState(() { _isLoading = true; _error = null; });
    
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      setState(() { _error = "Authentication token not found."; _isLoading = false; });
      return;
    }

    try {
      final result = await _apiService.getMyHistory(token, filters: filters);
      if (!mounted) return;
      setState(() {
        _history = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ฟังก์ชันสำหรับแปลง docstat เป็น String และสี (เหมือนเดิม)
  (String, Color) _getStatusInfo(String docstat) {
    switch (docstat) {
      case '05': return ('Ready to update to SAP', Colors.green);
      case 'RJ': return ('Rejected', Colors.orange);
      case '06': return ('Canceled', Colors.red);
      default: return (docstat, Colors.grey);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // ดึง Role จาก Provider เพื่อตัดสินใจว่าจะแสดง UI แบบไหน
    final userRole = Provider.of<AuthProvider>(context, listen: false).userProfile?.role;

    return Scaffold(
      // ไม่ต้องมี AppBar เพราะ MainScreen จัดการให้แล้ว
      body: RefreshIndicator(
        onRefresh: () => _fetchHistory(),
        child: Column(
          children: [
            // --- แสดง Filter Panel ถ้าเป็น Admin/Dispatcher ---
            if (userRole == 'admin' || userRole == 'dispatcher')
              _buildFilterPanel(),

            // --- แสดง List ของข้อมูล ---
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI สำหรับ Filter (เฉพาะ Admin/Dispatcher) ---
Widget _buildFilterPanel() {
  // Helper function เพื่อ format วันที่สำหรับแสดงผล
  String formatDate(DateTime dt) => DateFormat('dd MMM yyyy').format(dt);

  return Card(
    margin: const EdgeInsets.all(8.0),
    elevation: 2,
    child: ExpansionTile( // ใช้ ExpansionTile เพื่อให้พับเก็บได้
      title: const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
      leading: const Icon(Icons.filter_alt_outlined),
      initiallyExpanded: true, // ให้แสดง Filter ตอนแรก
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // --- Filter by Shipment ID ---
              TextFormField(
                controller: _shipmentIdController,
                decoration: const InputDecoration(
                  labelText: 'Shipment ID',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // --- Filter by Route ---
              TextFormField(
                controller: _routeController,
                decoration: const InputDecoration(
                  labelText: 'Route',
                  prefixIcon: Icon(Icons.route_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // --- Filter by Date Range ---
              InkWell(
                onTap: _pickDateRange,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Appointment Date Range',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDateRange == null
                        ? 'Select a date range'
                        : '${formatDate(_selectedDateRange!.start)} - ${formatDate(_selectedDateRange!.end)}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // --- Action Buttons ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ปุ่ม Clear
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _shipmentIdController.clear();
                        _routeController.clear();
                        _selectedDateRange = null;
                      });
                      _fetchHistory(); // โหลดข้อมูลใหม่ทั้งหมด
                    },
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
                  
                  // ปุ่ม Search
                  ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                    onPressed: () {
                      final filters = <String, String>{};
                      if (_shipmentIdController.text.isNotEmpty) {
                        filters['shipid'] = _shipmentIdController.text;
                      }
                      if (_routeController.text.isNotEmpty) {
                        filters['route'] = _routeController.text;
                      }
                      if (_selectedDateRange != null) {
                        filters['apmdate_from'] = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
                        filters['apmdate_to'] = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
                      }
                      _fetchHistory(filters: filters);
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    ),
  );
}
  // --- UI สำหรับแสดงเนื้อหาหลัก ---
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_history.isEmpty) {
      return const Center(child: Text('ไม่มีประวัติงาน'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(_history[index]);
      },
    );
  }

  Widget _buildHistoryCard(Shipment shipment) {
    // UI Card เหมือนเดิม
    final statusInfo = _getStatusInfo(shipment.docstat ?? '');
   return Card(
  child: ListTile(
    leading: Icon(Icons.check_circle_outline, color: statusInfo.$2),
    title: Text('Shipment ${shipment.shipid}'),
    subtitle: Text(
      'ขนส่ง: ${shipment.vencode}\n'
      'ประเภทรถ: ${shipment.mshiptype?.cartypedes ?? 'ไม่ระบุ'}\n'
      'Route: ${shipment.route ?? 'N/A'}\n'
      'วันที่นัดรถ: ${DateFormat('dd/MM/yyyy').format(shipment.apmdate!)}\n'
      'เวลา: ${shipment.apmdate != null ? DateFormat('HH:mm')  .format(shipment.apmdate!) : 'N/A'}',
    ),
    isThreeLine: true,
    trailing: Text(
      statusInfo.$1,
      style: TextStyle(color: statusInfo.$2, fontWeight: FontWeight.bold),
    ),
  ),
);

  }
}