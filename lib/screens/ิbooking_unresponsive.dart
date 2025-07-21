import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';

/// หน้าจัดการ Shipment Unresponsive
/// แสดงรายการ shipment ที่ไม่มีการตอบสนองและรายการผู้ให้บริการที่สามารถรับงานได้
class BookingUnresponsiveScreen extends StatefulWidget {
  final String accessToken;
  final List<Shipment> unresponsiveShipments; // shipment ที่ unresponsive
  final String warehouseCode;
  final DateTime selectedDate;

  const BookingUnresponsiveScreen({
    Key? key,
    required this.accessToken,
    required this.unresponsiveShipments,
    required this.warehouseCode,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<BookingUnresponsiveScreen> createState() =>
      _BookingUnresponsiveScreenState();
}

class _BookingUnresponsiveScreenState extends State<BookingUnresponsiveScreen> {
  final ApiService _apiService = ApiService();

  // ===== STATE MANAGEMENT =====
  List<ServiceProvider> _availableProviders = []; // รายการผู้ให้บริการที่พร้อม
  Shipment? _selectedShipment; // shipment ที่เลือก
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableProviders();

    // เลือก shipment แรกโดยอัตโนมัติ
    if (widget.unresponsiveShipments.isNotEmpty) {
      _selectedShipment = widget.unresponsiveShipments.first;
    }
  }

  // ===== DATA LOADING =====

  /// โหลดรายการผู้ให้บริการที่สามารถรับงานได้
  Future<void> _loadAvailableProviders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: เรียก API เพื่อดึงรายการผู้ให้บริการ
      // ตัวอย่างข้อมูล mock data
      await Future.delayed(Duration(seconds: 1)); // จำลองการโหลด

      _availableProviders = [
        ServiceProvider(
          id: "P001",
          name: "บจก.เพ พี โลจิสติกส์ อินเตอร์ กรุ๊ป",
          vehicleType: "รถบรรทุก 6 ล้อ",
          isAvailable: true,
        ),
        ServiceProvider(
          id: "P002",
          name: "บจก.ชัยมนต์ โลจิสติกส์",
          vehicleType: "รถบรรทุก 10 ล้อ",
          isAvailable: true,
        ),
        ServiceProvider(
          id: "P003",
          name: "หจก.พรอินทรา",
          vehicleType: "รถกึ่งตรึม",
          isAvailable: true,
        ),
        ServiceProvider(
          id: "P004",
          name: "หจก.ศรีพงศ์การขนส่งปลอดภัย",
          vehicleType: "รถกึ่งตรึม",
          isAvailable: true,
        ),
        ServiceProvider(
          id: "P005",
          name: "หจก.สุวัจน์ อินเตอร์กรุ๊ปปลอดภัย",
          vehicleType: "รถกึ่งตรึม",
          isAvailable: true,
        ),
      ];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ===== ACTIONS =====

  /// มอบหมายงานให้ผู้ให้บริการ
  Future<void> _assignToProvider(ServiceProvider provider) async {
    if (_selectedShipment == null) return;

    setState(() => _isLoading = true);

    try {
      // TODO: เรียก API เพื่อมอบหมายงาน
      // await _apiService.assignShipmentToProvider(
      //   widget.accessToken,
      //   _selectedShipment!.shipid,
      //   provider.id,
      // );

      // จำลองการทำงาน
      await Future.delayed(Duration(seconds: 1));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'มอบหมาย Shipment ${_selectedShipment!.shipid} ให้ ${provider.name} แล้ว'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // กลับไปหน้าก่อนหน้า
      Navigator.pop(context, true); // ส่ง true เพื่อบอกว่ามีการเปลี่ยนแปลง
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// แสดง dialog ยืนยันการมอบหมาย
  void _showAssignConfirmation(ServiceProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการมอบหมาย'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shipment: ${_selectedShipment?.shipid}'),
              SizedBox(height: 8),
              Text('ผู้ให้บริการ: ${provider.name}'),
              SizedBox(height: 8),
              Text('ประเภทรถ: ${provider.vehicleType}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _assignToProvider(provider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  // ===== UI BUILD METHODS =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ===== APP BAR =====
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F51B5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'จัดเตรียมการจอง',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {}, // TODO: implement notification
          ),
        ],
      ),

      // ===== MAIN BODY =====
      body: _isLoading && _availableProviders.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : Column(
                  children: [
                    // ===== SHIPMENT INFO SECTION =====
                    _buildShipmentInfo(),

                    const SizedBox(height: 16),

                    // ===== PROVIDERS SECTION =====
                    _buildProvidersSection(),
                  ],
                ),

      // ===== BOTTOM NAVIGATION =====
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3F51B5),
        unselectedItemColor: Colors.grey,
        currentIndex: 1, // Booked tab
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.local_shipping_rounded),
                if (widget.unresponsiveShipments.length > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${widget.unresponsiveShipments.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Booked',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
        ],
      ),
    );
  }

  /// แสดงข้อมูล Shipment ที่เลือก
  Widget _buildShipmentInfo() {
    if (_selectedShipment == null) return Container();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'จัดหาบนส่วนอง',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),

          // Shipment Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shipment ${_selectedShipment!.shipid}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: 30/08/2025',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'คลัง: ${_getWarehouseName(_selectedShipment!.shippoint)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'จัดส่วนได้จังหวัด: ${_selectedShipment!.details.isNotEmpty ? _selectedShipment!.details.first.routedes : 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// แสดงรายการผู้ให้บริการ
  Widget _buildProvidersSection() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ผู้ให้บริการบนส่วง',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            // Providers List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _availableProviders.length,
                      itemBuilder: (context, index) {
                        return _buildProviderCard(_availableProviders[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// สร้าง Card ของผู้ให้บริการแต่ละคน
  Widget _buildProviderCard(ServiceProvider provider) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Row(
        children: [
          // Provider Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.vehicleType,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (!provider.isAvailable) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ไม่พร้อมให้บริการ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Select Button
          SizedBox(
            width: 80,
            height: 32,
            child: ElevatedButton(
              onPressed: provider.isAvailable && !_isLoading
                  ? () => _showAssignConfirmation(provider)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    provider.isAvailable ? Colors.blue[600] : Colors.grey[400],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'เลือก',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// แสดงหน้า Error
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60),
            SizedBox(height: 16),
            Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? 'ไม่สามารถโหลดข้อมูลได้',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAvailableProviders,
              child: Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }

  // ===== HELPER METHODS =====

  /// แปลงรหัสคลังเป็นชื่อ
  String _getWarehouseName(String? shippoint) {
    switch (shippoint) {
      case '1001':
        return 'WH7';
      case '1000':
        return 'SW';
      default:
        return shippoint ?? 'ไม่ระบุ';
    }
  }
}

// ===== MODELS =====

/// Model สำหรับผู้ให้บริการ
class ServiceProvider {
  final String id;
  final String name;
  final String vehicleType;
  final bool isAvailable;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.isAvailable,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      isAvailable: json['is_available'] ?? true,
    );
  }
}
