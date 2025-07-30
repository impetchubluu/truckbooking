import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:truck_booking_app/providers/user_profile_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
// สามารถวางไว้ในไฟล์ vendor_home_screen.dart หรือไฟล์ widgets/countdown_timer.dart
import 'dart:async';

class CountdownTimerWidget extends StatefulWidget {
  final DateTime deadline;

  const CountdownTimerWidget({super.key, required this.deadline});

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime(); // คำนวณครั้งแรก
    // สร้าง Timer ที่จะทำงานทุกๆ 1 วินาทีเพื่ออัปเดต UI
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    if (!mounted) return; // ตรวจสอบว่า Widget ยังอยู่ใน tree
    final now = DateTime.now().toUtc(); // ใช้ UTC เพื่อความแม่นยำ
    final deadlineUtc = widget.deadline.isUtc ? widget.deadline : widget.deadline.toUtc();

    if (now.isAfter(deadlineUtc)) {
      setState(() {
        _timeRemaining = Duration.zero;
      });
      _timer?.cancel(); // หยุด Timer เมื่อหมดเวลา
    } else {
      setState(() {
        _timeRemaining = deadlineUtc.difference(now);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // ยกเลิก Timer เสมอเมื่อ Widget ถูกทำลาย
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeRemaining == Duration.zero) {
      return const Text(
        "Time's up!",
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }

    // Format Duration เป็น mm:ss
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(_timeRemaining.inMinutes.remainder(60));
    final seconds = twoDigits(_timeRemaining.inSeconds.remainder(60));

    return Text(
      '$minutes:$seconds mins left',
      style: TextStyle(
        color: _timeRemaining.inMinutes < 5 ? Colors.red.shade700 : Colors.orange.shade800,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}
Future<bool> _showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String confirmText,
  Color? confirmColor,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: Text(confirmText),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  ) ?? false; // ถ้าผู้ใช้กดปิด Dialog โดยไม่เลือก ให้ถือว่าเป็น false
}


Future<Map<String, String>?> _showAcceptJobDialog(BuildContext context,State screenState, String shipId, List<CarProfile> availableCars) async {
  // เปลี่ยนเป็น CarProfile? เพื่อให้เราสามารถเก็บ Object รถทั้งคันที่ถูกเลือกได้
  CarProfile? selectedCar;
  final carNoteController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  
  // --- 1. แก้ไขการสร้าง DropdownMenuItem ---
  final carItems = availableCars.map((car) {
    bool isAvailable = car.stat == 'ใช้งาน';
    return DropdownMenuItem<CarProfile>( // <<-- เปลี่ยน Type เป็น CarProfile
      value: car, // <<-- ส่ง Object รถทั้งคันเป็น value
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${car.carlicense} (${car.cartypedes})',
              style: TextStyle(
                // ทำให้ข้อความจางลงถ้าใช้งานไม่ได้
                color: isAvailable ? Colors.black : Colors.grey.shade500,
              ),
            ),
          ),
          if (!isAvailable)
            const Icon(Icons.warning_amber_rounded, color: Color.fromARGB(255, 245, 78, 0), size: 18),
        ],
      ),
    );
  }).toList();

  return showDialog<Map<String, String>?>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: Text('Confirm Job: $shipId'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<CarProfile>( // <<-- เปลี่ยน Type เป็น CarProfile
                  value: selectedCar,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Select Car', border: OutlineInputBorder()),
                  items: carItems,
                  onChanged: (CarProfile? newValue) { // <<-- รับเป็น CarProfile
                    setDialogState(() {
                      selectedCar = newValue;

                      if (newValue != null && newValue.stat != 'ใช้งาน') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Warning: ${newValue.carlicense} could be not in service.'),
                            backgroundColor: const Color.fromARGB(255, 245, 49, 0),
                          ),
                        );
                      }
                    });
                  },
                  validator: (value) => value == null ? 'Please select a car' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: carNoteController,
                  decoration: const InputDecoration(labelText: 'Note (Optional)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
  // --- 1. ทำให้ onPressed เป็น async ---
  onPressed: () async { 
    if (formKey.currentState!.validate()) {
      // --- 2. ตรวจสอบสถานะรถ ---
      if (selectedCar!.stat != 'ใช้งาน') {
        // --- 3. แสดง Dialog ที่สอง และ "รอ" ผลลัพธ์ (true/false) ---
        final bool? confirmedWarning = await showDialog<bool>(
          context: context,
          barrierDismissible: false, // ไม่ให้กดข้างนอกเพื่อปิด
          builder: (ctx) => AlertDialog(
            title: const Text('⚠️ Warning: Car Not In Service'),
            content: Text(
                'The selected car "${selectedCar!.carlicense}" is not in service.\n\nAre you sure you want to proceed with this car?'),
            actions: [
              // ปุ่ม Cancel จะ pop Dialog ที่สองและคืนค่า false
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              // ปุ่ม OK/Proceed จะ pop Dialog ที่สองและคืนค่า true
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Proceed Anyway'),
              ),
            ],
          ),
        );

        // --- 4. ตรวจสอบผลลัพธ์จาก Dialog ที่สอง ---
        // ถ้าผู้ใช้ไม่กดยืนยัน (กด Cancel หรือ ปิดไป) ให้ออกจากฟังก์ชันนี้เลย
        if (confirmedWarning != true) {
          return; 
        }
        
        // ถ้าผู้ใช้กดยืนยัน (confirmedWarning == true)
        // ให้ทำรายการต่อไป... (โค้ดจะไหลไปที่ pop Dialog แรกด้านล่าง)
      }

      // --- 5. ถ้าผ่านทุกเงื่อนไข (รถใช้งานได้ หรือ ผู้ใช้ยืนยันรถที่ใช้งานไม่ได้) ---
      // ให้ pop Dialog แรก พร้อมส่งข้อมูลกลับไป
      if (screenState.mounted) { // ตรวจสอบ mounted อีกครั้งหลัง await
        Navigator.of(context).pop({
          'carLicense': selectedCar!.carlicense,
          'carNote': carNoteController.text,
        });
      }
    }
  },
  child: const Text('Confirm'),
),
          ],
        );
      },
    ),
  );
}
// สำหรับ Reject
Future<String?> _showRejectJobDialog(BuildContext context, String shipId) async {
  final reasonController = TextEditingController();
  return showDialog<String?>(
      context: context,
      builder: (context) {
          return AlertDialog(
              title: Text('Reject Job: $shipId'),
            
              actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => Navigator.of(context).pop(reasonController.text),
                      child: const Text('Reject'),
                  ),
              ],
          );
      });
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
      Provider.of<UserProfileProvider>(context, listen: false).fetchUserProfile(token);
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

void _handleAccept(Shipment shipment) async {
  final allCars = Provider.of<UserProfileProvider>(context, listen: false).availableCars;

  if (allCars.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ไม่พบข้อมูลรถที่ใช้งานได้'), backgroundColor: Colors.orange),
    );
    return;
  }

  final String? selectedCarType = shipment.cartype;
  final filteredCars = allCars.where((car) => car.cartype == selectedCarType).toList();

  if (filteredCars.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ไม่พบรถที่ตรงตามประเภทที่ต้องการ'), backgroundColor: Colors.orange),
    );
    return;
  }

  // แสดง Dialog สำหรับการเลือก car
  final input = await _showAcceptJobDialog(context, this, shipment.shipid, filteredCars);
  if (input == null) return; // ผู้ใช้กดยกเลิก

  // เช็คว่า car ที่เลือกเป็น "ไม่ใช้งาน" หรือไม่


  final confirmed = await _showConfirmationDialog(
      context: context,
      title: "Confirm Acceptance?",
      content: "Are you sure you want to accept this job with car license ${input['carLicense']}?",
      confirmText: "ACCEPT",
      confirmColor: Colors.green
  );

  if (!confirmed) return;

  final token = Provider.of<AuthProvider>(context, listen: false).token;
  if (token == null) return;

  // แสดง Loading
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accepting job...')));

  try {
    await _apiService.confirmShipment(token, shipment.shipid, input['carLicense']!, input['carNote']);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job accepted successfully!'), backgroundColor: Colors.green));
    _refreshJobs();
  } catch (e) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to accept job: $e'), backgroundColor: Colors.red));
  }
}



void _handleReject(Shipment shipment) async {
    final reason = await _showRejectJobDialog(context, shipment.shipid);
    if (reason == null) return; // ผู้ใช้กดยกเลิก

    final confirmed = await _showConfirmationDialog(
        context: context,
        title: "Confirm Rejection?",
        content: "Are you sure you want to reject this job?",
        confirmText: "REJECT",
        confirmColor: Colors.red
    );

    if (!confirmed) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejecting job...')));

    try {
        await _apiService.rejectShipment(token, shipment.shipid, reason);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job rejected.'), backgroundColor: Colors.orange));
        _refreshJobs();
    } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to reject job: $e'), backgroundColor: Colors.red));
    }
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
  DateTime? deadline;  
  const responseTimeoutMinutes = 30; // ค่าตัวแปรเวลา

  // ตรวจสอบให้แน่ใจว่าเวลาที่ได้มาเป็น UTC
  if (shipment.assigned_at != null) {
    final assignedAtUtc = shipment.assigned_at!.isUtc 
                      ? shipment.assigned_at! 
                      : shipment.assigned_at!.toUtc();

    // คำนวณเวลาสิ้นสุด
    deadline = assignedAtUtc.add(const Duration(minutes: responseTimeoutMinutes));
  }

  // เช็คสถานะ docstat ว่าเป็น 'BC' หรือไม่
  bool isBcJob = shipment.docstat == 'BC';

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
                if (deadline != null)
                  CountdownTimerWidget(deadline: deadline)
                else
                  const Text(
                    "N/A", // กรณีไม่มีเวลา assigned_at มา
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'นัดรับสินค้า: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
            Text(
              'ประเภทรถ: ${shipment.mshiptype?.cartypedes ?? 'N/A'}',
              style: theme.textTheme.bodyMedium,
            ),
            const Divider(height: 20),
            _buildInfoRow(Icons.location_on_outlined, 'จังหวัด:', shipment.mprovince?.provname ?? 'N/A'),
            const SizedBox(height: 12),
            
            // เงื่อนไขการแสดงปุ่ม
            if (isBcJob) 
              Row(
  mainAxisAlignment: MainAxisAlignment.end,  // ตั้งค่าตรงนี้ให้ปุ่มไปชิดขวา
  children: [
    ElevatedButton(
      onPressed: () => _handleAccept(shipment),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        shadowColor: Colors.grey  
      ),
      child: const Text('ACCEPT BC JOB'),
    ),
  ],
)
            else 
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _handleReject(shipment); 
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                    child: const Text('REJECT'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleAccept(shipment),
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