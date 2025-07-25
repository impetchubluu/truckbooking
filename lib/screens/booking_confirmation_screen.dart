// lib/screens/booking_confirmation_screen.dart
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../models/api_models.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final BookingRound round;

  const BookingConfirmationScreen({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    // คัดกรองเอาเฉพาะ Shipment ที่รอการยืนยัน (docstat '03')
    final shipmentsToConfirm = round.shipments.where((s) => s.docstat == '03').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmation'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Date, Shipment ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              // TODO: Implement search functionality
            ),
          ),
        ),
      ),
      body: shipmentsToConfirm.isEmpty
          ? const Center(child: Text('No shipments to confirm in this round.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: shipmentsToConfirm.length,
              itemBuilder: (context, index) {
                return _buildShipmentCard(context, shipmentsToConfirm[index]);
              },
            ),
      // (Optional) เพิ่มปุ่ม Confirm All ที่ด้านล่าง
      // bottomNavigationBar: Padding(
      //   padding: const EdgeInsets.all(16.0),
      //   child: ElevatedButton(
      //     onPressed: () { /* TODO: call confirm API */ },
      //     child: const Text('Confirm All Shipments'),
      //   ),
      // ),
    );
  }

  Widget _buildShipmentCard(BuildContext context, Shipment shipment) {
    final theme = Theme.of(context);
    final vendorCode = shipment.mvendor?.vencode ?? 'N/A Vendor';
    final vendorName = shipment.mvendor?.venname ?? 'N/A Vendor';
    final carLicense = shipment.carlicense ?? 'N/A';
    final carType = shipment.mshiptype?.cartypedes ?? 'N/A';
    final appointmentDate = shipment.apmdate != null
        ? DateFormat('dd/MM/yyyy').format(shipment.apmdate!)
        : 'N/A';
    // สมมติว่า Vendor มีรูป Profile (ถ้าไม่มีก็ใช้ Icon แทน)
 String vendorInitials = '...';
  if (vendorCode.isNotEmpty && vendorCode != 'N/A Vendor') {
    // แยกชื่อด้วยช่องว่าง แล้วเอาตัวอักษรแรกของ 2 คำแรก (ถ้ามี)
    final nameParts = vendorCode.split(' ');
    if (nameParts.isNotEmpty) {
      vendorInitials = nameParts.first[0];
      if (nameParts.length > 1) {
        vendorInitials += nameParts[1][0];
      }
    }
  }
    return Card(
    margin: const EdgeInsets.symmetric(vertical: 6.0),
    elevation: 2.0,
    color: Colors.green.shade50,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Row 1: Shipment ID and Date ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipment ${shipment.shipid}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Date : $appointmentDate',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
              ),
            ],
          ),
          const Divider(height: 16),
          // --- Row 2: Car Info ---
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: Colors.grey.shade800, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(carType, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('No. ทะเบียน $carLicense'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // --- Row 3: Vendor Info ---
          Row(
            children: [
              // --- [จุดแก้ไข] เปลี่ยนจาก CircleAvatar ที่มีรูป เป็นแบบมีตัวอักษร ---
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade700, // เปลี่ยนสีพื้นหลังได้ตามต้องการ
                child: Text(
                  vendorInitials.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              // -------------------------------------------------------------
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$vendorCode: $vendorName', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}