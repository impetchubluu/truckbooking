import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  // ตัวอย่างข้อมูล mock (เปลี่ยนเป็นข้อมูลจริงได้)
  int totalShipments = 132;
  int totalRounds = 7;
  int fourWheelCount = 60;
  int sixWheelCount = 45;
  int tenWheelCount = 27;
  String lastBookingDate = '15/07/2025';

  // เลือกช่วงวันที่
  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;

        // 👉 ตรงนี้ไว้สำหรับ fetch ข้อมูลจริงจาก backend
        // fetchDataByDateRange(_startDate, _endDate);
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สรุปผลการจัดจอง')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 🔘 ปุ่มเลือกช่วงวันที่
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _startDate != null && _endDate != null
                        ? 'ช่วง: ${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
                        : 'ยังไม่เลือกช่วงวันที่',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('เลือกช่วงวันที่'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 🔝 วันที่จองล่าสุด (ด้านบน)
            _buildSummaryCard(
              title: 'วันที่มีการจองล่าสุด',
              value: lastBookingDate,
              icon: Icons.calendar_today,
              color: Colors.grey.shade200,
            ),

            const SizedBox(height: 20),
            const Text('แดชบอร์ดสรุปผล',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            _buildSummaryCard(
              title: 'จำนวน Shipment ที่จองแล้ว',
              value: '$totalShipments รายการ',
              icon: Icons.local_shipping,
              color: Colors.green.shade100,
            ),
            const SizedBox(height: 12),

            _buildSummaryCard(
              title: 'จำนวนรอบที่จัดส่ง',
              value: '$totalRounds รอบ',
              icon: Icons.sync_alt_rounded,
              color: Colors.blue.shade100,
            ),

            const SizedBox(height: 20),
            const Text('จำแนกตามประเภทรถ:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            _buildSummaryCard(
              title: 'รถ 4 ล้อ',
              value: '$fourWheelCount รายการ',
              icon: Icons.fire_truck_outlined,
              color: Colors.orange.shade100,
            ),
            const SizedBox(height: 8),

            _buildSummaryCard(
              title: 'รถ 6 ล้อ',
              value: '$sixWheelCount รายการ',
              icon: Icons.fire_truck_rounded,
              color: Colors.purple.shade100,
            ),
            const SizedBox(height: 8),

            _buildSummaryCard(
              title: 'รถ 10 ล้อ',
              value: '$tenWheelCount รายการ',
              icon: Icons.fire_truck,
              color: Colors.red.shade100,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: color,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
