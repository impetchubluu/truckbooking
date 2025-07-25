// lib/screens/booked_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/api_models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'booking_confirmation_screen.dart'; // หน้าจอรายละเอียด (รูปขวา)

class BookedScreen extends StatefulWidget {
  const BookedScreen({super.key});

  @override
  State<BookedScreen> createState() => _BookedScreenState();
}

class _BookedScreenState extends State<BookedScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<BookingRound>> _roundsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      setState(() {
        _roundsFuture = _apiService.getRoundsPendingConfirmation(token);
      });
    } else {
      _roundsFuture = Future.value([]);
    }
  }
  
  Future<void> _handleConfirmRound(int roundId) async {
    // แสดง loading dialog
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      await _apiService.confirmRoundAssignments(token!, roundId);
      Navigator.of(context).pop(); // ปิด loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยืนยันการจ่ายงานในรอบสำเร็จ!'), backgroundColor: Colors.green)
      );
      _loadData(); // โหลดข้อมูลใหม่
    } catch(e) {
      Navigator.of(context).pop(); // ปิด loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red)
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booked Confirmation')),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: FutureBuilder<List<BookingRound>>(
          future: _roundsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('ไม่มีรอบที่รอการยืนยัน'));
            }

            final rounds = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rounds.length,
              itemBuilder: (context, index) {
                final round = rounds[index];
                // คัดกรองเฉพาะ Shipment ที่มีสถานะ '03'
                final pendingShipments = round.shipments.where((s) => s.docstat == '03').toList();
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pendingShipments.length} shipments had booking already!',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BookingConfirmationScreen(
                                      round: round, // ส่งข้อมูลรอบทั้งหมดไป
                                    ),
                                  )
                                );
                              },
                              child: const Text('Recheck'), // หรือ 'View'
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _handleConfirmRound(round.id),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100),
                              child: const Text('Confirm'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}