import 'dart:async';
import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';

/// หน้าจอรายละเอียดรอบการจอง - แสดงระบบจองอัตโนมัติ
/// ฟีเจอร์หลัก:
/// - นับถอยหลังเวลาแบบเรียลไทม์
/// - จองอัตโนมัติ 2 รอบ (รอบละ 30 นาที)
/// - จัดการสถานะ shipment (Pending, Accept, Cancel, Unresponsive)
/// - ควบคุม Hold/Unhold และ manual booking
class RoundDetailScreen extends StatefulWidget {
  final BookingRound round; // ข้อมูลรอบการจองที่เลือก
  final String accessToken; // Token สำหรับ API calls
  final String warehouseCode; // รหัสคลังสินค้า
  final DateTime selectedDate; // วันที่เลือก

  const RoundDetailScreen({
    Key? key,
    required this.round,
    required this.accessToken,
    required this.warehouseCode,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<RoundDetailScreen> createState() => _RoundDetailScreenState();
}

class _RoundDetailScreenState extends State<RoundDetailScreen> {
  // ===== SERVICES & CONTROLLERS =====
  final ApiService _apiService = ApiService();

  // ===== STATE MANAGEMENT =====
  String selectedStatus = 'Pending'; // สถานะที่เลือกในตัวกรอง
  Timer? _countdownTimer; // Timer สำหรับนับถอยหลัง
  Timer? _autoRefreshTimer; // Timer สำหรับ refresh อัตโนมัติ

  // ===== TIME & ROUND MANAGEMENT =====
  Duration _timeUntilStart = Duration.zero; // เวลาที่เหลือก่อนเริ่มรอบ
  Duration _timeUntilEnd = Duration.zero; // เวลาที่เหลือก่อนจบรอบ
  int _currentRound = 1; // รอบปัจจุบัน (1 หรือ 2)
  BookingStatus _roundStatus = BookingStatus.waitingToStart; // สถานะของรอบ

  // ===== DATA MANAGEMENT =====
  List<Shipment> _allShipments = []; // shipment ทั้งหมด
  List<Shipment> _filteredShipments = []; // shipment ที่กรองแล้ว
  Map<String, int> _statusCounts = {}; // จำนวนในแต่ละสถานะ

  // ===== UI STATE =====
  bool _isLoading = false; // สถานะกำลังโหลด

  // ===== LIFECYCLE METHODS =====

  @override
  void initState() {
    super.initState();

    // คัดลอกข้อมูล shipment จาก widget
    _allShipments = List.from(widget.round.shipments);

    // Debug ข้อมูลพื้นฐานก่อนเริ่มระบบ
    print('=== INIT DEBUG ===');
    print('Round name: ${widget.round.name}');
    print('Round time: ${widget.round.time}');
    print('Round time hour: ${widget.round.time?.hour}');
    print('Round time minute: ${widget.round.time?.minute}');
    print('Selected date: ${widget.selectedDate}');
    print('Current time: ${DateTime.now()}');
    print('==================');

    // เริ่มระบบการจองและ refresh
    _initializeBookingSystem();
    _startAutoRefresh();
    _updateStatusCounts();
    _filterShipmentsByStatus();
  }

  @override
  void dispose() {
    // ยกเลิก Timer ทั้งหมดเมื่อออกจากหน้า
    _countdownTimer?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // ===== CORE BOOKING LOGIC =====

  /// เริ่มต้นระบบการจอง - ตรวจสอบเวลาและกำหนดสถานะเริ่มต้น
  void _initializeBookingSystem() {
    final now = DateTime.now();
    final roundTime = _combineDateTime(widget.selectedDate, widget.round.time!);

    // ตรวจสอบเวลาปัจจุบันและกำหนดสถานะ
    if (now.isBefore(roundTime)) {
      // ===== ยังไม่ถึงเวลาเริ่ม =====
      _roundStatus = BookingStatus.waitingToStart;
      _timeUntilStart = roundTime.difference(now);
      _startCountdownToStart();
    } else if (now.isBefore(roundTime.add(Duration(minutes: 30)))) {
      // ===== รอบที่ 1 (30 นาทีแรก) =====
      _roundStatus = BookingStatus.round1Active;
      _currentRound = 1;
      _timeUntilEnd = roundTime.add(Duration(minutes: 30)).difference(now);
      _startCountdownToEnd();
      _autoBookAvailableShipments(); // เริ่มจองอัตโนมัติ
    } else if (now.isBefore(roundTime.add(Duration(minutes: 60)))) {
      // ===== รอบที่ 2 (30 นาทีที่สอง) =====
      _roundStatus = BookingStatus.round2Active;
      _currentRound = 2;
      _timeUntilEnd = roundTime.add(Duration(minutes: 60)).difference(now);
      _startCountdownToEnd();
    } else {
      // ===== หมดเวลาแล้ว =====
      _roundStatus = BookingStatus.finished;
      _markUnresponsiveShipments();
    }
  }

  /// เริ่มนับถอยหลังก่อนเริ่มรอบ
  /// จะทำงานทุกวินาทีจนกว่าจะถึงเวลาเริ่มรอบ
  void _startCountdownToStart() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timeUntilStart = _timeUntilStart - Duration(seconds: 1);

        // เมื่อหมดเวลารอ -> เริ่มรอบที่ 1
        if (_timeUntilStart.inSeconds <= 0) {
          print('Timer finished - Starting Round 1');
          timer.cancel();

          // เปลี่ยนเป็นรอบที่ 1
          _roundStatus = BookingStatus.round1Active;
          _currentRound = 1;
          _timeUntilEnd = Duration(minutes: 30);

          // เริ่มจองอัตโนมัติและนับถอยหลังใหม่
          _autoBookAvailableShipments();
          _startCountdownToEnd();
        }
      });
    });
  }

  /// เริ่มนับถอยหลังสำหรับรอบที่กำลังทำงาน
  /// จะเปลี่ยนจากรอบที่ 1 -> รอบที่ 2 -> เสร็จสิ้น
  void _startCountdownToEnd() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timeUntilEnd = _timeUntilEnd - Duration(seconds: 1);

        // เมื่อหมดเวลารอบปัจจุบัน
        if (_timeUntilEnd.inSeconds <= 0) {
          timer.cancel();

          if (_currentRound == 1) {
            // ===== จบรอบที่ 1 -> เริ่มรอบที่ 2 =====
            print('Round 1 finished - Starting Round 2');
            _roundStatus = BookingStatus.round2Active;
            _currentRound = 2;
            _timeUntilEnd = Duration(minutes: 30);

            // จองเฉพาะ shipment ที่ยัง pending
            _autoBookPendingShipments();
            _startCountdownToEnd();
          } else {
            // ===== จบรอบที่ 2 -> เสร็จสิ้น =====
            print('Round 2 finished - Marking unresponsive');
            _roundStatus = BookingStatus.finished;
            _markUnresponsiveShipments();
          }
        }
      });
    });
  }

  // ===== AUTO BOOKING FUNCTIONS =====

  /// จองอัตโนมัติในรอบที่ 1 - จองทุก shipment ที่พร้อม
  /// เงื่อนไข: ไม่ hold และไม่ใช่ Booked/Cancel
  Future<void> _autoBookAvailableShipments() async {
    if (_isLoading) return; // ป้องกันการทำงานซ้ำ

    setState(() => _isLoading = true);

    try {
      // กรอง shipment ที่สามารถจองได้
      final shipmentsToBook = _allShipments
          .where((s) =>
              !s.isOnHold && // ไม่ได้ hold
              s.docstat != 'Booked' && // ยังไม่ถูกจอง
              s.docstat != 'Cancel') // ยังไม่ถูกยกเลิก
          .toList();

      // จองทีละรายการพร้อมหน่วงเวลา
      for (final shipment in shipmentsToBook) {
        try {
          await _bookShipment(shipment);
          // หน่วงเวลาเล็กน้อยเพื่อไม่ให้ API overwhelm
          await Future.delayed(Duration(milliseconds: 100));
        } catch (e) {
          print('Failed to book shipment ${shipment.shipid}: $e');
        }
      }

      // รีเฟรชข้อมูลหลังจองเสร็จ
      await _refreshShipmentData();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// จองอัตโนมัติในรอบที่ 2 - จองเฉพาะ shipment ที่ยัง pending
  /// สำหรับ shipment ที่ไม่มีคนรับในรอบแรก
  Future<void> _autoBookPendingShipments() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // กรอง shipment ที่ยัง pending จากรอบแรก
      final pendingShipments = _allShipments
          .where((s) => s.docstat == 'Pending' && !s.isOnHold)
          .toList();

      // จองทีละรายการ
      for (final shipment in pendingShipments) {
        try {
          await _bookShipment(shipment);
          await Future.delayed(Duration(milliseconds: 100));
        } catch (e) {
          print('Failed to book shipment ${shipment.shipid}: $e');
        }
      }

      await _refreshShipmentData();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ส่งคำขอจอง shipment ผ่าน API
  /// ใช้ ApiService.requestBooking() ที่มีอยู่แล้ว
  Future<void> _bookShipment(Shipment shipment) async {
    try {
      await _apiService.requestBooking(widget.accessToken, shipment.shipid);
      print('Successfully booked shipment: ${shipment.shipid}');
    } catch (e) {
      print('Error booking shipment ${shipment.shipid}: $e');
      rethrow; // ส่งต่อ error เพื่อให้ caller จัดการ
    }
  }

  /// ทำเครื่องหมาย shipment ที่ไม่มีการตอบสนองเป็น Unresponsive
  /// เรียกใช้หลังจากหมดเวลารอบที่ 2
  void _markUnresponsiveShipments() {
    // Mark shipments ที่ยังเป็น Pending หลังจากหมดเวลา เป็น Unresponsive
    // ในระบบจริงอาจต้องเรียก API เพื่ออัพเดท status ใน backend
    setState(() {
      for (int i = 0; i < _allShipments.length; i++) {
        if (_allShipments[i].docstat == 'Pending') {
          // TODO: เรียก API เพื่ออัพเดท status เป็น Unresponsive
          // หรือสร้าง shipment object ใหม่ด้วย status ที่เปลี่ยน
        }
      }
      _updateStatusCounts();
      _filterShipmentsByStatus();
    });
  }

  // ===== DATA REFRESH =====

  /// เริ่ม Auto refresh - รีเฟรชข้อมูลทุก 15 วินาที
  /// เพื่อดูการเปลี่ยนแปลงสถานะจาก server
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      // ไม่ refresh ขณะที่กำลังโหลดอยู่
      if (!_isLoading) {
        _refreshShipmentData();
      }
    });
  }

  /// ดึงข้อมูล shipment ล่าสุดจาก API
  /// เรียกใช้เมื่อต้องการอัพเดทข้อมูลจาก server
  Future<void> _refreshShipmentData() async {
    try {
      // ดึงข้อมูลรอบการจองล่าสุด
      final updatedRounds = await _apiService.getBookingRounds(
          widget.accessToken, widget.selectedDate, widget.warehouseCode);

      // หารอบที่ตรงกับรอบปัจจุบัน
      final updatedRound = updatedRounds.firstWhere(
        (r) => r.id == widget.round.id,
        orElse: () => widget.round, // ใช้ข้อมูลเดิมถ้าไม่เจอ
      );

      // อัพเดทข้อมูลและ UI
      setState(() {
        _allShipments = updatedRound.shipments;
        _updateStatusCounts();
        _filterShipmentsByStatus();
      });
    } catch (e) {
      print('Error refreshing data: $e');
      // ไม่แสดง error ใน UI เพราะเป็น background refresh
    }
  }

  /// อัพเดทจำนวน shipment ในแต่ละสถานะ
  /// สำหรับแสดงตัวเลขในปุ่มกรอง เช่น "Pending (5)"
  void _updateStatusCounts() {
    _statusCounts = {
      'Ready': _allShipments
          .where((s) => s.docstat == 'Ready' || s.docstat == null)
          .length,
      'Pending': _allShipments.where((s) => s.docstat == 'Pending').length,
      'Booked': _allShipments.where((s) => s.docstat == 'Booked').length,
      'Cancel': _allShipments.where((s) => s.docstat == 'Cancel').length,
    };
  }

  /// กรอง shipment ตามสถานะที่เลือก
  /// อัพเดท _filteredShipments สำหรับแสดงใน ListView
  void _filterShipmentsByStatus() {
    setState(() {
      switch (selectedStatus) {
        case 'Pending':
          _filteredShipments = _allShipments
              .where((s) => s.docstat == 'Pending' || s.docstat == null)
              .toList();
          break;
        case 'Accept':
          _filteredShipments =
              _allShipments.where((s) => s.docstat == 'Accept').toList();
          break;
        case 'Cancel':
          _filteredShipments =
              _allShipments.where((s) => s.docstat == 'Cancel').toList();
          break;
        case 'Unresponsive':
          _filteredShipments =
              _allShipments.where((s) => s.docstat == 'Unresponsive').toList();
          break;
        default:
          _filteredShipments = _allShipments;
      }
    });
  }

  // ===== MANUAL ACTIONS =====

  /// สลับสถานะ Hold/Unhold ของ shipment
  /// เรียกใช้เมื่อผู้ใช้กดปุ่ม Hold หรือ Unhold
  Future<void> _manualHoldToggle(Shipment shipment) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // เรียก API เพื่อเปลี่ยนสถานะ hold
      final updatedShipment = await _apiService.holdShipment(
          widget.accessToken, shipment.shipid, !shipment.isOnHold);

      // อัพเดทข้อมูลใน memory
      setState(() {
        final index =
            _allShipments.indexWhere((s) => s.shipid == shipment.shipid);
        if (index != -1) {
          _allShipments[index] = updatedShipment;
        }
        _updateStatusCounts();
        _filterShipmentsByStatus();
      });

      // แสดงข้อความสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updatedShipment.isOnHold
              ? 'Shipment ${shipment.shipid} ถูก Hold แล้ว'
              : 'Shipment ${shipment.shipid} ถูกยกเลิก Hold แล้ว'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // แสดงข้อความ error
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

  /// จอง shipment แบบ manual
  /// เรียกใช้เมื่อผู้ใช้กดปุ่มจองในแต่ละ shipment card
  Future<void> _manualBookShipment(Shipment shipment) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _bookShipment(shipment);
      await _refreshShipmentData(); // รีเฟรชเพื่อดูการเปลี่ยนแปลง

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ส่งคำขอจอง Shipment ${shipment.shipid} แล้ว'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการจอง: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ===== UI HELPER FUNCTIONS =====

  /// สร้างข้อความสถานะตามรอบปัจจุบัน
  /// แสดงในส่วนหัวของหน้าจอ
  String _getStatusText() {
    switch (_roundStatus) {
      case BookingStatus.waitingToStart:
        return 'ยังไม่ถึงเวลา : ${_formatDuration(_timeUntilStart)}';
      case BookingStatus.round1Active:
        return 'รอบที่ 1 กำลังดำเนินการ : ${_formatDuration(_timeUntilEnd)}';
      case BookingStatus.round2Active:
        return 'รอบที่ 2 กำลังดำเนินการ : ${_formatDuration(_timeUntilEnd)}';
      case BookingStatus.finished:
        return 'เสร็จสิ้นแล้ว';
    }
  }

  /// เลือกสีพื้นหลังตามสถานะรอบ
  /// ใช้แสดงในกรอบสถานะ
  Color _getStatusColor() {
    switch (_roundStatus) {
      case BookingStatus.waitingToStart:
        return Colors.orange[100]!; // สีส้มอ่อน - รอเริ่ม
      case BookingStatus.round1Active:
      case BookingStatus.round2Active:
        return Colors.green[100]!; // สีเขียวอ่อน - กำลังทำงาน
      case BookingStatus.finished:
        return Colors.grey[100]!; // สีเทาอ่อน - เสร็จสิ้น
    }
  }

  /// แปลง Duration เป็น format HH:MM:SS
  /// สำหรับแสดงเวลานับถอยหลัง
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  /// รวม DateTime และ TimeOfDay เป็น DateTime เดียว
  /// ใช้สำหรับคำนวณเวลาของรอบ
  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    final combined =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    print('Combined DateTime: $combined');
    return combined;
  }

  // ===== UI BUILD METHODS =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ===== APP BAR =====
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F51B5),
        title: const Text(
          'จัดเตรียมการจอง',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // แสดง loading indicator หรือปุ่ม refresh
          if (_isLoading)
            Container(
              margin: EdgeInsets.all(16),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshShipmentData,
            ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {}, // TODO: implement notification
          ),
        ],
      ),

      // ===== MAIN BODY =====
      body: Column(
        children: [
          // ===== HEADER INFO SECTION =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // ข้อมูลรอบและสถานะ
                Row(
                  children: [
                    // ชื่อรอบและเวลา
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.round.name} : ${widget.round.time?.format(context) ?? "เวลาไม่ระบุ"}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // สถานะปัจจุบันและเวลานับถอยหลัง
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusText(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== STATUS FILTER BUTTONS =====
                // ใช้ SingleChildScrollView เพื่อป้องกัน overflow
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusButton('Pending', Colors.yellow[700]!),
                      const SizedBox(width: 8),
                      _buildStatusButton('Accept', Colors.green[700]!),
                      const SizedBox(width: 8),
                      _buildStatusButton('Cancel', Colors.red[700]!),
                      const SizedBox(width: 8),
                      _buildStatusButton('Unresponsive', Colors.grey[700]!),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ===== SHIPMENTS LIST =====
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshShipmentData, // Pull-to-refresh
              child: _filteredShipments.isEmpty
                  ? // Empty state - แสดงเมื่อไม่มี shipment ในสถานะที่เลือก
                  Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'ไม่มี Shipment ในสถานะ $selectedStatus',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : // Shipment list - แสดงรายการ shipment ที่กรองแล้ว
                  ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredShipments.length,
                      itemBuilder: (context, index) {
                        return _buildShipmentCard(_filteredShipments[index]);
                      },
                    ),
            ),
          ),
        ],
      ),

      // ===== BOTTOM NAVIGATION =====
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3F51B5),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_rounded), label: 'Booked'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
        ],
      ),
    );
  }

  /// สร้างปุ่มกรองสถานะ
  /// แสดงชื่อสถานะและจำนวน shipment ในสถานะนั้น
  Widget _buildStatusButton(String status, Color color) {
    final isSelected = selectedStatus == status;
    final count = _statusCounts[status] ?? 0;

    return GestureDetector(
      onTap: () {
        // เปลี่ยนสถานะที่เลือกและกรองข้อมูลใหม่
        setState(() {
          selectedStatus = status;
          _filterShipmentsByStatus();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          // เปลี่ยนสีพื้นหลังตามการเลือก
          color: isSelected ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$status ($count)', // แสดงชื่อสถานะและจำนวน
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// สร้าง Card แสดงข้อมูล shipment แต่ละรายการ
  /// รวมข้อมูลพื้นฐาน, สถานะ, และปุ่มควบคุม
  Widget _buildShipmentCard(Shipment shipment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER ROW =====
          // แสดง ID และ status tags
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Shipment ID
              Text(
                'Shipment ${shipment.shipid}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Status Tags Row
              Row(
                children: [
                  // Hold/Ready Status Tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: shipment.isOnHold
                          ? Colors.red[300] // แดง = Hold
                          : Colors.orange[300], // ส้ม = Ready
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      shipment.isOnHold ? 'Hold' : 'Ready',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Document Status Tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColorForShipment(shipment.docstat),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      shipment.docstat ??
                          'Pending', // แสดง Pending ถ้าเป็น null
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ===== SHIPMENT DETAILS =====

          // ประเภทรถ
          Row(
            children: [
              const Text('ประเภทรถ : ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
              Text(shipment.mshiptype?.cartypedes ?? 'ไม่ระบุ',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w400)),
            ],
          ),
          const SizedBox(height: 4),

          // จังหวัดปลายทาง
          Row(
            children: [
              const Text('จัดส่งจังหวัดปลาย : ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
              Expanded(
                child: Text(
                  shipment.details.isNotEmpty
                      ? (shipment.details.first.routedes ?? 'N/A')
                      : 'N/A',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // คลังสินค้า
          Row(
            children: [
              const Text('คลัง : ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
              Text(
                // แปลงรหัสคลังเป็นชื่อที่อ่านง่าย
                shipment.shippoint == '1001'
                    ? 'WH7'
                    : shipment.shippoint == '1000'
                        ? 'SW'
                        : (shipment.shippoint ?? 'ไม่ระบุ'),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              ),
            ],
          ),

          // ปริมาตร (แสดงเฉพาะเมื่อมีข้อมูล)
          if (shipment.volumeCbm != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('ปริมาตร : ',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                Text('${shipment.volumeCbm!.toStringAsFixed(2)} CBM',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w400)),
              ],
            ),
          ],

          // ===== ACTION BUTTONS =====
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // ปุ่มจอง (แสดงเฉพาะเมื่อสถานะเป็น Pending)
              if (shipment.docstat == 'Pending' ||
                  shipment.docstat == null) ...[
                ElevatedButton.icon(
                  onPressed:
                      _isLoading ? null : () => _manualBookShipment(shipment),
                  icon: Icon(Icons.send, size: 16),
                  label: Text('จอง'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    minimumSize: Size(80, 32),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // ปุ่ม Hold/Unhold (แสดงเสมอ)
              ElevatedButton.icon(
                onPressed:
                    _isLoading ? null : () => _manualHoldToggle(shipment),
                icon: Icon(shipment.isOnHold ? Icons.play_arrow : Icons.pause,
                    size: 16),
                label: Text(shipment.isOnHold ? 'ยกเลิก Hold' : 'Hold'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: shipment.isOnHold
                      ? Colors.orange[600] // ส้ม = ยกเลิก Hold
                      : Colors.red[600], // แดง = Hold
                  foregroundColor: Colors.white,
                  minimumSize: Size(80, 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// กำหนดสีของ status tag ตามสถานะ shipment
  /// ใช้สำหรับ tag แสดงสถานะในแต่ละ card
  Color _getStatusColorForShipment(String? status) {
    switch (status) {
      case 'Ready':
        return Colors.blue[700]!; // น้ำเงิน = พร้อม
      case 'Pending':
        return Colors.yellow[700]!; // เหลือง = รอดำเนินการ
      case 'Booked':
        return Colors.green[700]!; // เขียว = จองแล้ว
      case 'Cancel':
        return Colors.red[700]!; // แดง = ยกเลิก
      default:
        return Colors.blue[700]!; // น้ำเงิน = default
    }
  }
}

// ===== ENUMS =====

/// สถานะของรอบการจอง
/// ใช้สำหรับควบคุม flow การทำงานของระบบ
enum BookingStatus {
  waitingToStart, // รอเริ่มรอบ - ยังไม่ถึงเวลา
  round1Active, // รอบที่ 1 กำลังทำงาน - 30 นาทีแรก
  round2Active, // รอบที่ 2 กำลังทำงาน - 30 นาทีหลัง
  finished, // เสร็จสิ้นรอบแล้ว - หลัง 60 นาที
}
