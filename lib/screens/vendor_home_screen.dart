import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Shipment>> _shipmentsFuture;

  @override
  void initState() {
    super.initState();
    // ดึงข้อมูลงานทันทีที่หน้าจอถูกสร้าง โดยใช้ token จาก AuthProvider
    // ใช้ listen: false ใน initState
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      _shipmentsFuture = _apiService.getShipments(token);
    } else {
      // Handle case where token is null (should not happen if routed correctly)
      _shipmentsFuture = Future.value([]);
    }
  }

  // ฟังก์ชันสำหรับ Refresh ข้อมูล
  Future<void> _refreshJobs() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      setState(() {
        _shipmentsFuture = _apiService.getShipments(token);
      });
    }
    return _shipmentsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshJobs,
        child: FutureBuilder<List<Shipment>>(
          future: _shipmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _buildErrorView(snapshot.error.toString());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyView();
            }

            final shipments = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: shipments.length,
              itemBuilder: (context, index) {
                return _buildJobCard(shipments[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('Failed to load jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _refreshJobs, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
     return Center(
         child: ListView( // ใช้ ListView เพื่อให้ RefreshIndicator ทำงานได้
             children: [
                 Padding(
                   padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.3),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                         const Icon(Icons.inbox_rounded, size: 80, color: Colors.grey),
                         const SizedBox(height: 16),
                         const Text('No New Jobs', style: TextStyle(fontSize: 22, color: Colors.grey)),
                         const Text('You have no new job assignments at the moment.'),
                         const SizedBox(height: 20),
                         OutlinedButton.icon(
                             icon: const Icon(Icons.refresh),
                             label: const Text("Refresh"),
                             onPressed: _refreshJobs,
                         )
                     ],
                   ),
                 ),
             ],
         ),
     );
  }


  Widget _buildJobCard(Shipment shipment) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Viewing details for Shipment ${shipment.shipid}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shipment ${shipment.shipid}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  // อาจจะแสดงเวลาที่เหลือในการตัดสินใจ
                  // Text('15:30 mins left', style: TextStyle(color: Colors.orange.shade700)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'นัดรับสินค้า: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
              Text(
                'ประเภทรถ: ${shipment.cartype ?? 'N/A'}',
                style: theme.textTheme.bodyMedium,
              ),
              const Divider(height: 20),
              _buildInfoRow(Icons.person_outline, 'ลูกค้า:', shipment.customerName ?? 'N/A'),
              _buildInfoRow(Icons.location_on_outlined, 'จังหวัด:', shipment.provname ?? 'N/A'),
              _buildInfoRow(Icons.inventory_2_outlined, 'จำนวน/ปริมาตร:', '${shipment.quantity ?? '-'} ชิ้น / ${shipment.volumeCbm ?? '-'} CBM'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      // TODO: Implement Reject Logic
                      print('Rejecting job: ${shipment.shipid}');
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                    child: const Text('REJECT'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement Accept Logic
                      print('Accepting job: ${shipment.shipid}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('ACCEPT'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}