import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';

class ShipmentDetailScreen extends StatefulWidget {
  final String shipId;
  final String accessToken;

  const ShipmentDetailScreen({
    super.key,
    required this.shipId,
    required this.accessToken,
  });

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  final ApiService _apiService = ApiService();
  Shipment? _shipment;
  bool _isLoading = true;
  bool _isActionLoading = false; // State สำหรับ Action Buttons
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchShipmentDetails();
  }

  Future<void> _fetchShipmentDetails({bool showLoading = true}) async {
    if (showLoading) setState(() { _isLoading = true; });
    _errorMessage = null;
    try {
      final shipmentData = await _apiService.getShipmentDetails(widget.accessToken, widget.shipId);
      if (mounted) setState(() => _shipment = shipmentData);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted && showLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleHoldStatus() async {
    if (_shipment == null || _isActionLoading) return;
    final bool newHoldStatus = !_shipment!.isOnHold;
    setState(() => _isActionLoading = true);
    try {
      await _apiService.holdShipment(widget.accessToken, widget.shipId, newHoldStatus);
      await _fetchShipmentDetails(showLoading: false); // Refresh ข้อมูล
    } catch (e) {
      if (mounted) _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }
  Future<void> _performQuickBook() async {
     if (_shipment == null || _isActionLoading) return;
     setState(() => _isActionLoading = true);

     try {
         final updatedShipment = await _apiService.requestBooking(widget.accessToken, widget.shipId);
         if (mounted) {
             setState(() {
                 _shipment = updatedShipment;
             });
             _showSuccessSnackBar('Shipment ${updatedShipment.shipid} has been sent to Grade ${updatedShipment.current_grade_to_assign} vendors!');
            
             Future.delayed(const Duration(seconds: 2), () {
                 if (mounted) Navigator.of(context).pop(true); // ส่ง true กลับไปเพื่อบอกว่ามีการเปลี่ยนแปลง
             });
         }
     } catch (e) {
         if (mounted) _showErrorSnackBar(e.toString());
     } finally {
         if (mounted) setState(() => _isActionLoading = false);
     }
  }
  // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

  void _showErrorSnackBar(String message) {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text(message), backgroundColor: Colors.redAccent));
  }
  void _showSuccessSnackBar(String message) {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text(message), backgroundColor: Colors.green.shade700));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดเตรียมการจอง'),
        actions: [
          IconButton(
            icon: const Badge(label: Text('1'), child: Icon(Icons.notifications_none)),
            onPressed: () {},
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)))
              : _shipment == null
                  ? const Center(child: Text('Shipment not found.'))
                  : _buildDetailsView(),
    );
  }

  Widget _buildDetailsView() {
    bool canBook = !_shipment!.isOnHold && ['01', '06', 'RJ'].contains(_shipment!.docstat);

    return Stack( // ใช้ Stack เพื่อแสดง Loading Overlay
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Shipment is ready to book!', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              _buildShipmentHeaderCard(_shipment!),
              const SizedBox(height: 16),
              _buildDetailsTable(_shipment!),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isActionLoading ? null : _toggleHoldStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _shipment!.isOnHold ? Colors.blue.shade700 : Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_shipment!.isOnHold ? 'Press to Un-Hold' : 'Press to Hold'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: canBook && !_isActionLoading ? _performQuickBook : null, // <<--- เรียกฟังก์ชันใหม่ และเช็คเงื่อนไข
                style: ElevatedButton.styleFrom(
                  backgroundColor: canBook ? Colors.green.shade600 : Colors.grey, // สีปุ่มเปลี่ยนตามเงื่อนไข
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('จองด่วน'),
              )
            ],
          ),
        ),
        if (_isActionLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildShipmentHeaderCard(Shipment shipment) {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shipment ${shipment.shipid}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // TODO: ใช้ apmdate จริงจาก shipment object
            Text('Date : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
            Text('คลัง : ${shipment.provname ?? 'N/A'}'), //provname ควรจะมาจาก shippoint หรือมีข้อมูลแยก
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Text('${shipment.shiptypeDesc ?? 'N/A'}, จัดส่งจังหวัดปลายทางกรุงเทพ'), // provname ควรจะมาจากจังหวัดปลายทาง
              ],
            )
          ],
        ),
      ),
    );
  }

// Widget นี้จะรับ Shipment ทั้งก้อนเข้ามา
// แล้วสร้างตารางที่มีหลายแถวจาก shipment.details
Widget _buildDetailsTable(Shipment shipment) {
  const tableHeaderStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
  const cellTextStyle = TextStyle(fontSize: 12);

  Widget buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, style: tableHeaderStyle, textAlign: TextAlign.center),
    );
  }

  Widget buildDataCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, style: cellTextStyle, textAlign: align),
    );
  }

  // สร้าง List ของ TableRow สำหรับข้อมูลแต่ละ detail
  List<TableRow> detailRows = shipment.details.map((detail) {
    // ดึงข้อมูลจาก 'detail' object
    final String doid = detail.doid;
    final String cusname = detail.cusname;
    final String route = detail.route;
    final String cusid = detail.cusid;
    final String routedes= detail.routedes ?? 'N/A'; // ใช้ N/A ถ้า routedes เป็น null
    final String volumn = detail.volumn.toStringAsFixed(3);
    final String dlvdate = DateFormat('dd/MM').format(detail.dlvdate);

    return TableRow(
      // สลับสีพื้นหลังเพื่อให้อ่านง่าย
      decoration: BoxDecoration(
        color: shipment.details.indexOf(detail) % 2 == 0 
               ? Colors.white 
               : Colors.grey.shade100,
      ),
      children: [
        buildDataCell(doid, align: TextAlign.center),
        buildDataCell(cusname, align: TextAlign.center),
        buildDataCell(routedes, align: TextAlign.center),
        buildDataCell(volumn, align: TextAlign.center),
      ],
    );
  }).toList();


  // ถ้าไม่มี details เลย ให้แสดงข้อความแทน
  if (shipment.details.isEmpty) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: Text('No delivery details found.')),
    );
  }

  // ประกอบตารางทั้งหมดเข้าด้วยกัน
  return Table(
    border: TableBorder.all(color: Colors.grey.shade300, width: 1),
    columnWidths: const {
      0: FlexColumnWidth(1.8), // DO ID
      1: FlexColumnWidth(3),   // Customer Name
      2: FlexColumnWidth(1.8), // Date
      3: FlexColumnWidth(1.3), // Volume
    },
    children: [
      // 1. Header Row
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade200),
        children: [
          buildHeaderCell('DO ID'),
          buildHeaderCell('Customer'),
          buildHeaderCell('Routedes'),
          buildHeaderCell('Volume'),
        ],
      ),
      
      
      ...detailRows,
    ],
  );
}
}