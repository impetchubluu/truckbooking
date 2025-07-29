import 'dart:async';
import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import 'shipment_detail_screen.dart';

class RoundDetailScreen extends StatefulWidget {
  final int roundId;
  final String roundName;
  final TimeOfDay? roundTime;
  final String accessToken;
  final DateTime selectedDate;
  final String warehouseCode;

  const RoundDetailScreen({
    super.key,
    required this.roundId,
    required this.roundName,
    this.roundTime,
    required this.accessToken,
    required this.selectedDate,
    required this.warehouseCode,
  });

  @override
  State<RoundDetailScreen> createState() => _RoundDetailScreenState();
}

class _RoundDetailScreenState extends State<RoundDetailScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  BookingRound? _roundDetails;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAllocating = false;
  bool _autoAllocated = false;

  // สำหรับ Tab Bar
  late TabController _tabController;
  final List<String> _tabs = ['Pending', 'Accepted', 'Canceled', 'Unresponsive'];
  
  // สำหรับ Timer ต่างๆ
  Timer? _allocationTimer;
  Timer? _roundTimeCheckTimer;
  Duration? _remainingTime;
  static const int responseTimeoutMinutes = 30;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchRoundDetailsAndAutoAssign();
    _startRoundTimeChecker();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _allocationTimer?.cancel();
    _roundTimeCheckTimer?.cancel();
    super.dispose();
  }

  // เริ่มตรวจสอบเวลาเพื่อทำ Auto-Allocate
  void _startRoundTimeChecker() {
    if (widget.roundTime == null) return;

    final now = DateTime.now();
    final roundDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      widget.roundTime!.hour,
      widget.roundTime!.minute,
    );

    // ถ้าถึงเวลารอบแล้วให้ทำ allocate ทันที
    if (now.isAfter(roundDateTime)) {
      _handleAllocate(isAuto: true);
      return;
    }

    // ตั้ง Timer ตรวจสอบทุกนาที
    _roundTimeCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final currentTime = DateTime.now();
      if (currentTime.isAfter(roundDateTime)) {
        _handleAllocate(isAuto: true);
        timer.cancel();
      }
    });
  }

  Future<void> _fetchRoundDetailsAndAutoAssign() async {
    setState(() { 
      _isLoading = true; 
      _errorMessage = null; 
    });
    
    try {
      var round = await _apiService.getBookingRoundDetails(widget.accessToken, widget.roundId);
      
      if (mounted && (round.shipments.isEmpty)) {
        print("Round is empty. Auto-assigning all ready shipments...");
        String warehouseCode = widget.warehouseCode;

        if (widget.warehouseCode == 'SW') {
          warehouseCode = '1000';
          print("Corrected warehouse code from 'SW' to '1000'");
        } else if (widget.warehouseCode == 'WH7') {
          warehouseCode = '1001';
          print("Corrected warehouse code from 'WH7' to '1001'");
        }

        _apiService.assignAllToRound(
          widget.accessToken,
          widget.roundId,
          widget.selectedDate,
          warehouseCode,
        ).then((_) {
          if(mounted) _fetchRoundDetailsOnly();
        }).catchError((e) {
          if (mounted) {
            setState(() {
              _errorMessage = "Auto-assign failed: $e";
              _isLoading = false;
            });
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _roundDetails = round;
            _checkAndStartTimer();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() { 
        _errorMessage = e.toString(); 
        _isLoading = false; 
      });
    }
  }

  Future<void> _fetchRoundDetailsOnly() async {
    try {
      final round = await _apiService.getBookingRoundDetails(widget.accessToken, widget.roundId);
      if(mounted){
        setState(() {
          _roundDetails = round;
          _checkAndStartTimer();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _checkAndStartTimer() {
    _allocationTimer?.cancel();

    if (_roundDetails == null || _roundDetails!.shipments.isEmpty) {
      // ถ้ายังไม่มี shipments และถึงเวลารอบแล้ว ให้ทำ allocate
      final now = DateTime.now();
      if (widget.roundTime != null) {
        final roundDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          widget.roundTime!.hour,
          widget.roundTime!.minute,
        );
        if (now.isAfter(roundDateTime)) {
          _handleAllocate(isAuto: true);
        }
      }
      return;
    }
    
    final pendingShipments = _roundDetails!.shipments
        .where((s) => (s.docstat == '02' || s.docstat == 'BC') && s.assigned_at != null)
        .toList();
    
    if (pendingShipments.isEmpty) {
      setState(() => _remainingTime = null);
      return;
    }
    
    pendingShipments.sort((a, b) => b.assigned_at!.compareTo(a.assigned_at!));
    final DateTime startTime = pendingShipments.first.assigned_at!;
    final endTime = startTime.add(const Duration(minutes: responseTimeoutMinutes));
    
    if (DateTime.now().isBefore(endTime)) {
      _startTimer(endTime);
    } else {
      setState(() => _remainingTime = Duration.zero);
    }
  }
  
  void _startTimer(DateTime endTime) {
    _allocationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { 
        timer.cancel(); 
        return; 
      }
      
      final now = DateTime.now();
      if (now.toUtc().isAfter(endTime.toUtc())) {
        timer.cancel();
        setState(() => _remainingTime = Duration.zero);
        _fetchRoundDetailsOnly();
      } else {
        setState(() => _remainingTime = endTime.toUtc().difference(now.toUtc()));
      }
    });
  }

  Future<void> _handleAllocate({bool isAuto = false}) async {
    if (_isAllocating) return;
    
    setState(() {
      _isAllocating = true;
      if (isAuto) _autoAllocated = true;
    });
    
    try {
      await _apiService.allocateRound(widget.accessToken, widget.roundId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAuto 
              ? 'ระบบเริ่มจัดสรรงานอัตโนมัติตามเวลาที่กำหนด'
              : 'เริ่มกระบวนการจัดสรรงานสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchRoundDetailsOnly();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'), 
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAllocating = false);
    }
  }
  
  List<Shipment> _getFilteredShipments(String status) {
    if (_roundDetails == null) return [];
    
    switch (status) {
      case 'Pending':
        return _roundDetails!.shipments.where((s) => ['01', '02', 'BC'].contains(s.docstat)).toList();
      case 'Accepted':
        return _roundDetails!.shipments.where((s) => ['03', '04'].contains(s.docstat)).toList();
      case 'Canceled':
        return _roundDetails!.shipments.where((s) => ['06', 'RJ'].contains(s.docstat)).toList();
      case 'Unresponsive':
        return [];
      default:
        return _roundDetails!.shipments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียด: ${widget.roundName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final bool hasShipments = _roundDetails?.shipments.isNotEmpty ?? false;
    final bool isAllocated = _remainingTime != null;
    final now = DateTime.now();
    final roundDateTime = widget.roundTime != null 
      ? DateTime(now.year, now.month, now.day, widget.roundTime!.hour, widget.roundTime!.minute)
      : null;
    final isRoundTimePassed = roundDateTime != null && now.isAfter(roundDateTime);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // --- Header Section ---
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.roundName} : ${widget.roundTime?.format(context) ?? ""}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (roundDateTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _autoAllocated
                            ? 'จัดสรรงานอัตโนมัติแล้ว'
                            : isRoundTimePassed
                                ? 'พร้อมจัดสรรงานอัตโนมัติ'
                                : 'จะจัดสรรงานอัตโนมัติในเวลา ${widget.roundTime!.format(context)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _autoAllocated ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (hasShipments)
                ElevatedButton.icon(
                  onPressed: isAllocated || _isAllocating ? null : () => _handleAllocate(),
                  icon: _isAllocating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    isAllocated
                        ? '${_remainingTime!.inMinutes}:${(_remainingTime!.inSeconds % 60).toString().padLeft(2, '0')}'
                        : 'Allocate',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAllocated ? Colors.orange.shade100 : Colors.green.shade100,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // --- Tab Bar Section ---
          if (isAllocated)
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 20.0), 
              tabs: _tabs.map((tabName) {
                final count = _getFilteredShipments(tabName).length;
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tabName),
                      if(count > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onTap: (_) => setState(() {}),
            ),
          
          // --- Shipments List Section ---
          Expanded(
            child: hasShipments
              ? isAllocated
                ? TabBarView(
                    controller: _tabController,
                    children: _tabs.map((tabName) => _buildShipmentList(_getFilteredShipments(tabName))).toList(),
                  )
                : _buildShipmentList(_roundDetails!.shipments)
              : const Center(
                  child: Text("ไม่มี Shipment ในรอบนี้", style: TextStyle(color: Colors.grey)),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentList(List<Shipment> shipments) {
    if (shipments.isEmpty) {
      return const Center(child: Text('ไม่มีรายการ Shipment ในสถานะนี้'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0),
      itemCount: shipments.length,
      itemBuilder: (context, index) {
        final shipment = shipments[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            leading: Icon(Icons.local_shipping_outlined, color: Colors.blue.shade700),
            title: Text('Shipment ${shipment.shipid}'),
            subtitle: Text('สถานะ: ${shipment.docstat} - ${shipment.carlicense ?? 'N/A'}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ShipmentDetailScreen(
                    shipId: shipment.shipid,
                    accessToken: widget.accessToken,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}