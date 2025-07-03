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
              ? Center(child: Text('Error: $_errorMessage', style: TextStyle(color: Colors.red)))
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

  Widget _buildDetailsTable(Shipment shipment) {
    final tableHeaderStyle = TextStyle(fontWeight: FontWeight.bold);

    Widget buildCell(String text, {TextAlign align = TextAlign.left, TextStyle? style}) {
        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Text(text, textAlign: align, style: style),
        );
    }

    final int totalQuantity = shipment.details.fold(0, (sum, item) => sum + (item.quantity ?? 0));
    final double totalVolume = shipment.details.fold(0.0, (sum, item) => sum + (item.volume ?? 0.0));

    return Table(
        border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
        columnWidths: const {
            0: FlexColumnWidth(2), 1: FlexColumnWidth(3.5),
            2: FlexColumnWidth(2), 3: FlexColumnWidth(2),
        },
        children: [
            TableRow(
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                ),
                children: [
                    buildCell('DO', style: tableHeaderStyle),
                    buildCell('ที่อยู่จัดส่ง', style: tableHeaderStyle),
                    buildCell('จำนวนสินค้า', style: tableHeaderStyle, align: TextAlign.right),
                    buildCell('ปริมาตร', style: tableHeaderStyle, align: TextAlign.right),
                ]
            ),
            ...shipment.details.map((detail) => TableRow(
                children: [
                    buildCell(detail.doNumber),
                    buildCell(detail.shippingAddress ?? ''),
                    buildCell(detail.quantity?.toString() ?? '', align: TextAlign.right),
                    buildCell(detail.volume?.toStringAsFixed(2) ?? '', align: TextAlign.right),
                ]
            )),
            if (shipment.details.length < 5)
                ...List.generate(5 - shipment.details.length, (index) => TableRow(
                    children: List.generate(4, (_) => buildCell(''))
                )),
            TableRow(
                children: [
                    buildCell('จำนวนสินค้าทั้งหมด =', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(),
                    buildCell('$totalQuantity', align: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(),
                ]
            ),
            TableRow(
                 decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                ),
                children: [
                    buildCell('ปริมาตรรวม =', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(),
                    buildCell('${totalVolume.toStringAsFixed(2)} CBM', align: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(),
                ]
            ),
        ],
    );
  }
}