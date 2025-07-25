// lib/screens/dispatcher_home_screen.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:truck_booking_app/screens/manage_round_screen.dart';
import 'package:truck_booking_app/screens/round_detail_screen.dart';
import 'package:truck_booking_app/screens/shipment_detail_screen.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
// ignore: duplicate_ignore
// ignore: unused_import
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';


class DispatcherHomeScreen extends StatefulWidget {
  final String accessToken;

  const DispatcherHomeScreen({super.key, required this.accessToken});
  @override
  _DispatcherHomeScreenState createState() => _DispatcherHomeScreenState();
}

class _DispatcherHomeScreenState extends State<DispatcherHomeScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  String? _selectedWarehouseCode;
  String? warehouse;
  List<Warehouse> _warehouses = [];
  List<BookingRound> _bookingRounds = [];
  List<Shipment> _unassignedShipments = [];
  bool _showUnassignedShipments = false; 
  
  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final warehouses = await _apiService.getWarehouses(widget.accessToken);
      if (!mounted) return;
      
      _warehouses = warehouses;
      if (_warehouses.isNotEmpty) {
        _selectedWarehouseCode = _warehouses.first.code;
      }

      if (_selectedWarehouseCode != null) {
        await _fetchDataForSelectedFilters();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _fetchDataForSelectedFilters() async {
    if (_selectedWarehouseCode == null) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final roundsFuture = _apiService.getBookingRounds(widget.accessToken, _selectedDate, _selectedWarehouseCode!);
      final shipmentsFuture = _apiService.getUnassignedShipments(widget.accessToken, _selectedDate, _selectedWarehouseCode!);
      final results = await Future.wait([roundsFuture, shipmentsFuture]);

      if (!mounted) return;
      setState(() {
        _bookingRounds = results[0] as List<BookingRound>;
        _unassignedShipments = results[1] as List<Shipment>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showDatePicker() async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (newDate != null && newDate != _selectedDate) {
      setState(() { _selectedDate = newDate; });
      await _fetchDataForSelectedFilters();
    }
  }

  Future<void> _toggleHoldStatus(Shipment shipment) async {
    final originalHoldStatus = shipment.isOnHold;
    setState(() {
      shipment.isOnHold = !shipment.isOnHold;
    });

    try {
      await _apiService.holdShipment(widget.accessToken, shipment.shipid, shipment.isOnHold);
      _fetchDataForSelectedFilters(); // Refresh the list after action
    } catch (e) {
      setState(() { shipment.isOnHold = originalHoldStatus; });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error updating hold status: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading && _warehouses.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
            ? _buildErrorView()
            : RefreshIndicator(
                onRefresh: _fetchDataForSelectedFilters,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildBookingRoundsSection(),
                      const SizedBox(height: 16),
                      _buildShipmentsSection(),
                    ],
                  ),
                ),
              );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('Failed to load data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'An unknown error occurred.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _fetchDataForSelectedFilters, child: const Text('Retry'))
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _showDatePicker,
            child: InputDecorator(
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
              ),
              child: Text('รอบการจองวันที่ : ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (_warehouses.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedWarehouseCode,
                items: _warehouses.map((Warehouse wh) {
                  return DropdownMenuItem<String>(
                    value: wh.code,
                    child: Text('${wh.code} (${wh.name})'),
                  );
                }).toList(),
                 onChanged: (String? newValue) {
                if (newValue != null && newValue != _selectedWarehouseCode) {
                  setState(() {
                    _selectedWarehouseCode = newValue; // <-- จะ set ค่าเป็น '1000'
                  });
                  _fetchDataForSelectedFilters(); // <-- ฟังก์ชันนี้จะใช้ _selectedWarehouseCode ที่เป็น '1000' ไปเรียก API
                }
              },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBookingRoundsSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("กำหนดรอบการจอง", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                OutlinedButton(
  onPressed: () async {
    // Navigate ไปยังหน้า ManageRoundsScreen
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ManageRoundsScreen(
          accessToken: widget.accessToken,
          selectedDate: _selectedDate,
          warehouseCode: _selectedWarehouseCode!,
          initialRounds: _bookingRounds,
        ),
        fullscreenDialog: true, // ทำให้หน้านี้เปิดแบบ Modal
      ),
    );

    // ถ้ามีการ Save สำเร็จ (pop กลับมาเป็น true) ให้ Refresh ข้อมูล
    if (result == true) {
      _fetchDataForSelectedFilters();
    }
  },
  child: const Text("Manage")
),
              ],
            ),
            if (_bookingRounds.isEmpty && !_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('ยังไม่ระบุเวลาของรอบการจอง', style: TextStyle(color: Colors.grey)),
              )
            else
              ..._bookingRounds.map((round) => _buildRoundItem(round)),
          ],
        ),
      ),
    );
  }

 Widget _buildRoundItem(BookingRound round) {
   final timeFormatter = DateFormat('h:mm a'); 
  String formattedTime = 'N/A';
  if (round.time != null) {
    // แปลง TimeOfDay เป็น DateTime ชั่วคราวเพื่อใช้ formatter
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, round.time!.hour, round.time!.minute);
    formattedTime = timeFormatter.format(dt);
  }
  return ListTile(
    dense: true,
    title: Text(round.name),
    subtitle: Text("เวลา: $formattedTime, จำนวน ${round.shipments.length} รายการ"), // <-- length จะถูกต้องแล้ว
    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: () {
      // --- แก้ไขตรงนี้ ---
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RoundDetailScreen(
            roundId: round.id,
            roundName: round.name,
            roundTime: round.time,
            accessToken: widget.accessToken,
            selectedDate: _selectedDate,
            warehouseCode: _selectedWarehouseCode!,
          ),
        ),
      ).then((_) {
        // .then() จะทำงานเมื่อ pop กลับมาจาก RoundDetailScreen
        // ให้ refresh หน้า Home เพื่ออัปเดตข้อมูลล่าสุด
        _fetchDataForSelectedFilters();
      });
      // --------------------
    },
  );
}
Widget _buildShipmentsSection() {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- ส่วนหัวยังคงเหมือนเดิม ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4.0),
              child: Text("รายการ Shipments ทั้งหมด", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            // --- ปุ่ม View/Hide ---
            TextButton(
              onPressed: () {
                setState(() {
                  _showUnassignedShipments = !_showUnassignedShipments;
                });
              },
              child: Row(
                children: [
                  Text(_showUnassignedShipments ? "Hide" : "View"),
                  const SizedBox(width: 4),
                  Icon(
                    _showUnassignedShipments ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),

        // --- ส่วนเนื้อหาที่จะแสดง/ซ่อน ---
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _showUnassignedShipments
                      ? _buildShipmentsListView() // <-- ถ้า true, แสดง ListView
                      : _buildPlaceholderCard(), // <-- ถ้า false, แสดง Card ว่างๆ
                ),
        ),
      ],
    ),
  );
}
Widget _buildPlaceholderCard() {
  // Widget ที่จะแสดงตอนที่ List ถูกซ่อน
  return Card(
    key: const ValueKey('placeholder'), // Key สำหรับ AnimatedSwitcher
    child: InkWell(
      onTap: () {
        setState(() {
          _showUnassignedShipments = true;
        });
      },
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility_off_outlined, color: Colors.grey, size: 40),
              SizedBox(height: 8),
              Text("กด 'View' เพื่อแสดงรายการ", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    ),
  );
}
Widget _buildShipmentsListView() {
  // ยก Logic การสร้าง ListView มาไว้ที่นี่
  if (_unassignedShipments.isEmpty) {
    return const Card(
      key: ValueKey('emptyList'), // Key สำหรับ AnimatedSwitcher
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("ไม่มี Shipment ที่รอจัดสรร", style: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }

  return ListView.builder(
    key: const ValueKey('shipmentsList'), // Key สำหรับ AnimatedSwitcher
    itemCount: _unassignedShipments.length,
    itemBuilder: (context, index) {
      final shipment = _unassignedShipments[index];
      final bool isOnHold = shipment.isOnHold;
      
      // ... โค้ด Card ของคุณ (เหมือนเดิมเป๊ะๆ ไม่ต้องแก้) ...
      return Card(
      color: isOnHold ? Colors.grey.shade200 : Colors.blue.shade50,
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(Icons.local_shipping_outlined, color: Colors.grey.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if(shipment.shippoint == '1001')
                  const Text('คลัง: WH7', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  if(shipment.shippoint == '1000')
                  const Text('คลัง: SW', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  Text('Shipment ${shipment.shipid}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('วันที่นัดรถ: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                  Text('ประเภท: ${shipment.mshiptype?.cartypedes ?? 'ประเภทรถไม่ระบุ'}'),
                  Text('Route: ${shipment.route ?? 'N/A'}${shipment.details.isNotEmpty ? shipment.details.first.routedes : 'N/A'}'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // --- Tag สถานะ ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnHold ? Colors.red.shade600 : Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOnHold ? "Hold" : "Ready",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                // --- ปุ่ม View ---
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ShipmentDetailScreen(
                          shipId: shipment.shipid,
                          accessToken: widget.accessToken,
                        ),
                      ),
                    );
                  },
                  child: const Text("View"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    },
  );
}
}