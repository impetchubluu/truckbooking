// lib/screens/booked_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/api_models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class BookedScreen extends StatefulWidget {
  const BookedScreen({super.key});

  @override
  State<BookedScreen> createState() => _BookedScreenState();
}

class _BookedScreenState extends State<BookedScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Shipment>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _fetchOngoingOrders();
  }

  void _fetchOngoingOrders() {
    // ใช้ token จาก AuthProvider เพื่อเรียก API
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      setState(() {
        // --- เรียกใช้ฟังก์ชันใหม่จาก ApiService ---
        _ordersFuture = _apiService.getMyOngoingOrders(token);
      });
    } else {
      _ordersFuture = Future.value([]); // กรณีไม่มี token
    }
  }

  @override
  Widget build(BuildContext context) {
    // ไม่ต้องมี AppBar ที่นี่ เพราะ MainScreen จัดการให้แล้ว
    return RefreshIndicator(
        onRefresh: () async => _fetchOngoingOrders(),
        child: FutureBuilder<List<Shipment>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('ไม่มีงานที่กำลังทำอยู่'));
            }

            final orders = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                // คุณสามารถสร้าง Widget สำหรับแสดง Card ของ Order ได้ที่นี่
                return _buildOrderCard(orders[index]);
              },
            );
          },
        ),
      );
  }

Widget _buildOrderCard(Shipment shipment) {
  final theme = Theme.of(context);

  // Helper function to format date and time separately
  String formatDate(DateTime? dt) => dt != null ? DateFormat('dd MMM yyyy').format(dt) : 'N/A';
  String formatTime(DateTime? dt) => dt != null ? DateFormat('HH:mm').format(dt) : 'N/A';

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    elevation: 2.0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
      side: BorderSide(color: Colors.grey.shade300),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12.0),
      onTap: () {
        // TODO: Navigate to the full order detail screen
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shipment #${shipment.shipid}',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    // สามารถสร้าง helper function เพื่อแปลง docstat เป็นข้อความที่อ่านง่าย
                    "Confirmed", 
                    style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // --- Vehicle Details (รายละเอียดรถ) ---
            Text("Vehicle Details", style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.local_shipping_outlined, 'ประเภทรถ:', shipment.mshiptype?.cartypedes ?? 'N/A'),
            _buildInfoRow(Icons.numbers_rounded, 'ทะเบียน:', shipment.carlicense ?? 'N/A'),
            const SizedBox(height: 12),

            // --- Trip Details (รายละเอียดการเดินทาง) ---
            Text("Trip Details", style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.route_outlined, 'Route:', '${shipment.route ?? 'N/A'} - (${shipment.details.firstOrNull?.routedes ?? '...'})'),
            _buildInfoRow(Icons.location_on_outlined, 'จังหวัด:',  shipment.mprovince?.provname ?? 'N/A'),
            _buildInfoRow(Icons.calendar_today_outlined, 'วันที่นัด:', formatDate(shipment.apmdate)),
            _buildInfoRow(Icons.access_time_rounded, 'เวลานัด:', formatTime(shipment.apmdate)),
            _buildInfoRow(Icons.access_time_rounded, 'คาดว่าจะเสร็จภายใน:', '${shipment.mLeadTime?.leadTime.toInt() ?? 0} วัน'),
            const SizedBox(height: 16),
            
         
          ],
        ),
      ),
    ),
  );
}

// Helper Widget เพื่อสร้างแถวข้อมูล (ลดโค้ดซ้ำซ้อน)
Widget _buildInfoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        SizedBox(
          width: 80, // กำหนดความกว้างของ label ให้เท่ากันเพื่อความสวยงาม
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey.shade800),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
}