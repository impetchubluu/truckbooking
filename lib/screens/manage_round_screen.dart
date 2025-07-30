import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';

class ManageRoundsScreen extends StatefulWidget {
  final String accessToken;
  final DateTime selectedDate;
  final String warehouseCode;
  final List<BookingRound> initialRounds; // รับรอบที่มีอยู่แล้วมาแสดง

  const ManageRoundsScreen({
    super.key,
    required this.accessToken,
    required this.selectedDate,
    required this.warehouseCode,
    required this.initialRounds,
  });

  @override
  _ManageRoundsScreenState createState() => _ManageRoundsScreenState();
}

class _ManageRoundsScreenState extends State<ManageRoundsScreen> {
  final ApiService _apiService = ApiService();
  late List<TimeOfDay?> _rounds; // ใช้ List ของ TimeOfDay ที่เป็น nullable
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // แปลง initialRounds เป็น List ของ TimeOfDay สำหรับ UI
    _rounds = widget.initialRounds.map((r) => r.time).toList();
    if (_rounds.isEmpty) {
       _rounds.add(null); // เพิ่มช่องว่าง 1 ช่องถ้ายังไม่มีรอบเลย
    }
  }

  void _addRound() {
    setState(() {
      _rounds.add(null); // เพิ่มช่องว่างใหม่สำหรับเลือกเวลา
    });
  }

  void _removeRound(int index) {
    setState(() {
      _rounds.removeAt(index);
    });
  }

  Future<void> _selectTime(int index) async {
     final TimeOfDay? picked = await showTimePicker(
         context: context,
         initialTime: _rounds[index] ?? TimeOfDay.now(),
     );
     if (picked != null && picked != _rounds[index]) {
         setState(() {
             _rounds[index] = picked;
         });
     }
  }

  Future<void> _saveRounds() async {
     setState(() => _isSaving = true);
     try {
         // กรองเอาเฉพาะรอบที่ User เลือกเวลาแล้ว
         final validRounds = _rounds.where((time) => time != null).map((time) {
             return {"round_time_str": "${time!.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}"};
         }).toList();

         final requestData = SaveDayRoundsRequestData(
             roundDate: widget.selectedDate,
             warehouseCode: widget.warehouseCode,
             rounds: validRounds,
         );

         await _apiService.saveDayRounds(widget.accessToken, requestData);

         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rounds saved successfully!'), backgroundColor: Colors.green));
             Navigator.of(context).pop(true); // ส่ง true กลับไปเพื่อบอกให้หน้ารายการ Refresh
         }
     } catch (e) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save rounds: $e'), backgroundColor: Colors.red));
          }
     } finally {
         if (mounted) setState(() => _isSaving = false);
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการรอบเวลาการจอง'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _rounds.length,
                itemBuilder: (context, index) {
                  return _buildRoundEditorRow(index);
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, size: 40),
              onPressed: _addRound,
              color: Theme.of(context).primaryColor,
              tooltip: 'เพิ่มรอบ',
            ),
            const Text('เพิ่มรอบ'),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isSaving
           ? const Center(child: CircularProgressIndicator())
           : ElevatedButton(
              onPressed: _saveRounds,
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
      ),
    );
  }

  Widget _buildRoundEditorRow(int index) {
     final roundNumber = index + 1;
     final selectedTime = _rounds[index];
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 8.0),
       child: Row(
         children: [
           Text('รอบที่ $roundNumber', style: const TextStyle(fontSize: 16)),
           const SizedBox(width: 16),
           Expanded(
             child: InkWell(
               onTap: () => _selectTime(index),
               child: InputDecorator(
                 decoration: const InputDecoration(
                     border: OutlineInputBorder(),
                     contentPadding: EdgeInsets.symmetric(horizontal: 12),
                     suffixIcon: Icon(Icons.arrow_drop_down),
                 ),
                 child: Text(
                     selectedTime?.format(context) ?? 'เลือกเวลา',
                     style: TextStyle(
                         fontSize: 16,
                         color: selectedTime == null ? Colors.grey.shade600 : Colors.black,
                     ),
                 ),
               ),
             ),
           ),
           IconButton(
             icon: const Icon(Icons.delete_outline, color: Colors.red),
             onPressed: () => _removeRound(index),
           )
         ],
       ),
     );
  }
}