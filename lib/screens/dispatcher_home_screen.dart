// lib/screens/dispatcher_home_screen.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:truck_booking_app/screens/shipment_detail_screen.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
// ignore: duplicate_ignore
// ignore: unused_import
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// TODO: สร้างหน้าจอเหล่านี้ในอนาคต
// import 'round_detail_screen.dart';
// import 'manage_round_screen.dart';

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

  List<Warehouse> _warehouses = [];
  List<BookingRound> _bookingRounds = [];
  List<Shipment> _unassignedShipments = [];

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
                    setState(() { _selectedWarehouseCode = newValue; });
                    _fetchDataForSelectedFilters();
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
                  onPressed: () {
                    // TODO: Navigate to ManageRoundsScreen
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigate to Manage Rounds page')));
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
    return ListTile(
      dense: true,
      title: Text(round.name),
      subtitle: Text("เวลา: ${round.time.format(context)}, จำนวน ${round.shipments.length} รายการ"),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // TODO: Navigate to RoundDetailScreen(roundId: round.id)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Navigate to detail for ${round.name}')));
      },
    );
  }

 Widget _buildShipmentsSection() {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
              child: Text("รายการ Shipments ทั้งหมด", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _unassignedShipments.isEmpty
                      ? const Card(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("ไม่มี Shipment ที่รอจัดสรร", style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _unassignedShipments.length,
                          itemBuilder: (context, index) {
                            final shipment = _unassignedShipments[index];
                            final bool isOnHold = shipment.isOnHold;
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
                                          Text('Shipment ${shipment.shipid}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text('Date : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}  คลัง : ${shipment.provname ?? 'N/A'}'), // ใช้ apmdate จริง
                                          Text('รถ 4 ล้อ, จัดส่งจังหวัดปลายทางกรุงเทพ'), // Example detail line
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
                        ),
            ),
          ],
        ),
      );
    }
    }