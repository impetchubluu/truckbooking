import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Enums ---
enum ShipmentStatus {
  readyForBooking,
  awaitingVendorConfirmation,
  confirmedByVendor,
  allGradesRejected, // Renamed from allTiersRejected
  bookingFinalized,
  canceledByDispatcher,
}

// New: Enum for Vendor Grade
enum VendorGrade { A, B, C, D, unassigned }

enum UserRole { dispatcher, vendor }

// --- Data Models ---
class Shipment {
  final String shipmentNo;
  String? shipmentType;
  String? shippingType;
  String? doNo;
  final String route;
  final DateTime plannedCheckIn;
  String? shippingConType;

  String? vendorName; // Name of the vendor who confirmed
  String? assignedVendorId; // Actual ID of the vendor from your mvendor table
  VendorGrade? confirmedByGrade; // Grade of the vendor who confirmed

  String? vehicleRegNo;
  ShipmentStatus status;
  String? rejectionReason;
  String? cancellationReason;

  VendorGrade currentGradeToAssign; // The current grade the shipment is offered to
  final List<VendorGrade> gradeAssignmentOrder; // Defines the order of grades to try

  Shipment({
    required this.shipmentNo,
    this.shipmentType,
    this.shippingType,
    this.doNo,
    required this.route,
    required this.plannedCheckIn,
    this.shippingConType,
    this.vendorName,
    this.assignedVendorId,
    this.confirmedByGrade,
    this.vehicleRegNo,
    this.status = ShipmentStatus.readyForBooking,
    this.rejectionReason,
    this.cancellationReason,
    this.currentGradeToAssign = VendorGrade.A, // Default to Grade A
    this.gradeAssignmentOrder = const [VendorGrade.A, VendorGrade.B, VendorGrade.C, VendorGrade.D],
  });

  String get plannedDateFormatted =>
      DateFormat('yyyy-MM-dd HH:mm').format(plannedCheckIn.toLocal());

  VendorGrade? getNextGradeToAssignInOrder() {
    int currentIndex = gradeAssignmentOrder.indexOf(currentGradeToAssign);
    if (currentIndex != -1 && currentIndex < gradeAssignmentOrder.length - 1) {
      return gradeAssignmentOrder[currentIndex + 1];
    }
    return null; // No next grade in the defined order
  }
}

// Simulated Vendor User Model (in a real app, this would come from your backend)
class VendorUser {
  final String firebaseUid;
  final String vendorId; // From your mvendor table
  final String name;
  final VendorGrade grade;
  final String email;

  VendorUser({
    required this.firebaseUid,
    required this.vendorId,
    required this.name,
    required this.grade,
    required this.email,
  });
}


// --- Main App ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ระบบจองรถ',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurpleAccent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const ShipmentPage(),
    );
  }
}

// --- Shipment Page State Management ---
class ShipmentPage extends StatefulWidget {
  const ShipmentPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ShipmentPageState createState() => _ShipmentPageState();
}

class _ShipmentPageState extends State<ShipmentPage> {
  UserRole _currentUserRole = UserRole.dispatcher;
  VendorUser? _currentVendorUser; // To store details of the logged-in/simulated vendor

  final List<String> _availableVehicleTypes = [
    'รถกระบะ', 'รถกระบะตู้ทึบ', 'รถบรรทุก 4 ล้อ', 'รถบรรทุก 6 ล้อ',
    'รถบรรทุก 10 ล้อ', 'รถพ่วง', 'รถตู้เย็น', 'Other',
  ];

  final List<Shipment> _allShipments = [
    Shipment(shipmentNo: 'SHP001', route: 'Route A - North', plannedCheckIn: DateTime.now().add(const Duration(days: 5, hours: 10)), shipmentType: 'FTL', doNo: 'DO-1001', shippingConType: '20', currentGradeToAssign: VendorGrade.A),
    Shipment(shipmentNo: 'SHP002', route: 'Route B - East', plannedCheckIn: DateTime.now().add(const Duration(days: 6, hours: 14)), shipmentType: 'LTL', shippingType: 'รถกระบะตู้ทึบ', doNo: 'DO-1002', shippingConType: '20', currentGradeToAssign: VendorGrade.B, status: ShipmentStatus.awaitingVendorConfirmation),
    Shipment(shipmentNo: 'SHP003', route: 'Route C - West', plannedCheckIn: DateTime.now().add(const Duration(days: 7, hours: 9)), shipmentType: 'FTL', shippingType: 'รถบรรทุก 10 ล้อ', doNo: 'DO-1003', shippingConType: '20', status: ShipmentStatus.awaitingVendorConfirmation, currentGradeToAssign: VendorGrade.A),
    Shipment(shipmentNo: 'SHP004', route: 'Route D - South', plannedCheckIn: DateTime.now().add(const Duration(days: 8, hours: 16)), shipmentType: 'FTL', shippingType: 'รถพ่วง', doNo: 'DO-1004', shippingConType: '20', status: ShipmentStatus.confirmedByVendor, vendorName: 'GoodTransporter A', assignedVendorId: "V001A", confirmedByGrade: VendorGrade.A, vehicleRegNo: 'กท-1234A'),
    Shipment(shipmentNo: 'SHP005', route: 'Route E - Central', plannedCheckIn: DateTime.now().add(const Duration(days: 2, hours: 11)), shipmentType: 'FTL', doNo: 'DO-1005', shippingConType: '20', status: ShipmentStatus.readyForBooking, currentGradeToAssign: VendorGrade.C),
    Shipment(shipmentNo: 'SHP006', route: 'Route F - NorthEast', plannedCheckIn: DateTime.now().add(const Duration(days: 3, hours: 15)), shipmentType: 'FTL', shippingType: 'รถบรรทุก 6 ล้อ', doNo: 'DO-1006', shippingConType: '20', status: ShipmentStatus.allGradesRejected, rejectionReason: "All grades busy", currentGradeToAssign: VendorGrade.D), // Assuming D was the last tried
    Shipment(shipmentNo: 'SHP007', route: 'Route G - SouthWest', plannedCheckIn: DateTime.now().add(const Duration(days: 1, hours: 9)), shipmentType: 'LTL', shippingType: 'รถกระบะ', doNo: 'DO-1007', shippingConType: '20', status: ShipmentStatus.bookingFinalized, vendorName: "FastDelivery B Co.", assignedVendorId: "V007B", confirmedByGrade: VendorGrade.B, vehicleRegNo: "BD-5678B"),
    Shipment(shipmentNo: 'SHP008', route: 'Route H - Metro', plannedCheckIn: DateTime.now().add(const Duration(days: 4, hours: 13)), shipmentType: 'FTL', shippingType: 'รถบรรทุก 10 ล้อ', doNo: 'DO-1008', shippingConType: '20', status: ShipmentStatus.canceledByDispatcher, cancellationReason: "Customer request"),
  ];

  List<Shipment> _displayedShipments = [];
  final TextEditingController _filterController = TextEditingController();
  final Set<ShipmentStatus> _activeStatusFilters = {};
  final List<ShipmentStatus> _filterableStatuses = [
    ShipmentStatus.readyForBooking, ShipmentStatus.awaitingVendorConfirmation,
    ShipmentStatus.confirmedByVendor, ShipmentStatus.allGradesRejected,
    ShipmentStatus.bookingFinalized, ShipmentStatus.canceledByDispatcher,
  ];

  @override
  void initState() {
    super.initState();
    _updateDisplayedShipments();
  }

  void _updateDisplayedShipments([String query = '']) {
    setState(() {
      List<Shipment> tempFiltered;
      if (query.isEmpty) {
        tempFiltered = List.from(_allShipments);
      } else {
        tempFiltered = _allShipments.where((s) {
          final qLower = query.toLowerCase();
          return s.shipmentNo.toLowerCase().contains(qLower) ||
              s.route.toLowerCase().contains(qLower) ||
              (s.doNo?.toLowerCase().contains(qLower) ?? false) ||
              (s.shipmentType?.toLowerCase().contains(qLower) ?? false) ||
              (s.shippingType?.toLowerCase().contains(qLower) ?? false) ||
              s.plannedDateFormatted.contains(qLower);
        }).toList();
      }

      if (_activeStatusFilters.isNotEmpty) {
        tempFiltered = tempFiltered.where((s) => _activeStatusFilters.contains(s.status)).toList();
      }

      if (_currentUserRole == UserRole.vendor && _currentVendorUser != null) {
        _displayedShipments = tempFiltered.where((s) =>
                s.status == ShipmentStatus.awaitingVendorConfirmation &&
                s.currentGradeToAssign == _currentVendorUser!.grade)
            .toList();
      } else if (_currentUserRole == UserRole.dispatcher) {
        _displayedShipments = tempFiltered;
      } else {
        _displayedShipments = [];
      }
    });
  }

  void _toggleStatusFilter(ShipmentStatus status) {
    setState(() {
      // ignore: curly_braces_in_flow_control_structures
      if (_activeStatusFilters.contains(status)) _activeStatusFilters.remove(status);
      // ignore: curly_braces_in_flow_control_structures
      else _activeStatusFilters.add(status);
      _updateDisplayedShipments(_filterController.text);
    });
  }

  // Simulate fetching vendor details based on Firebase UID (replace with actual API call)
  Future<void> _simulateFetchCurrentVendorDetails(String firebaseUid, VendorGrade grade) async {
     // This is a MOCK. In a real app, you'd call your backend.
    setState(() {
      _currentVendorUser = VendorUser(
        firebaseUid: firebaseUid,
        vendorId: "SIM-${_getGradeText(grade).toUpperCase()}${firebaseUid.substring(0,3)}",
        name: "Simulated Vendor ${_getGradeText(grade)}",
        grade: grade,
        email: "vendor${_getGradeText(grade)}@example.com",
      );
      _updateDisplayedShipments(); // Refresh list for this vendor's grade
    });
  }


  void _switchUserRole(UserRole? newRole) {
    if (newRole != null) {
      setState(() {
        _currentUserRole = newRole;
        _filterController.clear();
        _activeStatusFilters.clear();
        if (newRole == UserRole.vendor) {
          // Default to simulating Vendor Grade A when switching to Vendor role
          // In a real app, this would come from the logged-in user's profile
          _simulateFetchCurrentVendorDetails("simulated_vendor_uid", VendorGrade.A);
        } else {
          _currentVendorUser = null;
        }
        _updateDisplayedShipments();
      });
    }
  }

  // For simulation: allow switching the grade of the current vendor view
  void _switchVendorGradeView(VendorGrade? grade) {
    if (grade != null && _currentUserRole == UserRole.vendor) {
       _simulateFetchCurrentVendorDetails("simulated_vendor_uid_for_${_getGradeText(grade)}", grade);
    }
  }


  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void setShipmentShippingType(Shipment shipment, String? newType) {
     setState(() {
      _allShipments.firstWhere((s) => s.shipmentNo == shipment.shipmentNo).shippingType = newType;
      _updateDisplayedShipments(_filterController.text);
    });
  }

  void requestVehicleBooking(Shipment shipment) {
     if (shipment.shippingType == null || shipment.shippingType!.isEmpty) {
      _showSnackbar('Please select a vehicle type (ประเภทรถ) before requesting booking.');
      return;
    }
    setState(() {
      final targetShipment = _allShipments.firstWhere((s) => s.shipmentNo == shipment.shipmentNo);
      targetShipment.status = ShipmentStatus.awaitingVendorConfirmation;
      targetShipment.currentGradeToAssign = targetShipment.gradeAssignmentOrder.first; // Start with the first grade in order
      targetShipment.vendorName = null;
      targetShipment.assignedVendorId = null;
      targetShipment.confirmedByGrade = null;
      targetShipment.vehicleRegNo = null;
      targetShipment.rejectionReason = null;
      _showSnackbar(
          'Requesting ${targetShipment.shippingType} for ${targetShipment.shipmentNo} (to Grade ${_getGradeText(targetShipment.currentGradeToAssign)})...');
      _updateDisplayedShipments(_filterController.text);
    });
  }

  void finalizeBooking(Shipment shipment) {
     setState(() {
      _allShipments.firstWhere((s) => s.shipmentNo == shipment.shipmentNo).status = ShipmentStatus.bookingFinalized;
      _showSnackbar(
          'Booking for ${shipment.shipmentNo} finalized with ${shipment.vendorName}. Data to DB/SAP.');
      _updateDisplayedShipments(_filterController.text);
    });
  }

  void cancelBookingByDispatcher(Shipment shipment) {
    setState(() {
      final targetShipment = _allShipments.firstWhere((s) => s.shipmentNo == shipment.shipmentNo);
      targetShipment.status = ShipmentStatus.canceledByDispatcher;
      targetShipment.cancellationReason = "Cancelled by Dispatcher";
      _showSnackbar(
          'Booking for ${targetShipment.shipmentNo} canceled. Vendor ${targetShipment.vendorName ?? ''} notified.');
      _updateDisplayedShipments(_filterController.text);
    });
  }

  void confirmByVendor(Shipment shipment) {
    if (_currentVendorUser == null) {
      _showSnackbar("Vendor information not available.");
      return;
    }
    if (shipment.currentGradeToAssign != _currentVendorUser!.grade) {
      _showSnackbar("Error: This shipment is not assigned to your grade (${_getGradeText(_currentVendorUser!.grade)}).");
      return;
    }

    setState(() {
      final targetShipment = _allShipments.firstWhere((s) => s.shipmentNo == shipment.shipmentNo);
      targetShipment.status = ShipmentStatus.confirmedByVendor;
      targetShipment.vendorName = _currentVendorUser!.name;
      targetShipment.assignedVendorId = _currentVendorUser!.vendorId;
      targetShipment.confirmedByGrade = _currentVendorUser!.grade;
      targetShipment.vehicleRegNo = "GR${_getGradeText(_currentVendorUser!.grade)}-${UniqueKey().toString().substring(0, 4).toUpperCase()}";
      _showSnackbar(
          '${targetShipment.shipmentNo} confirmed by ${targetShipment.vendorName} (Grade ${_getGradeText(targetShipment.confirmedByGrade!)}).');
      _updateDisplayedShipments(_filterController.text);
    });
  }

  void rejectByVendor(Shipment shipment) {
    if (_currentVendorUser == null) {
      _showSnackbar("Vendor information not available.");
      return;
    }
     if (shipment.currentGradeToAssign != _currentVendorUser!.grade) {
      _showSnackbar("Error: This shipment is not assigned to your grade (${_getGradeText(_currentVendorUser!.grade)}).");
      return;
    }

    setState(() {
      final targetShipment = _allShipments.firstWhere((s) => s.shipmentNo == shipment.shipmentNo);
      String rejectedGradeStr = _getGradeText(targetShipment.currentGradeToAssign);
      targetShipment.rejectionReason = "Rejected by Grade $rejectedGradeStr Vendor: ${_currentVendorUser!.name} (Simulated: Vehicle unavailable)";
      _showSnackbar('${targetShipment.shipmentNo} rejected by Grade $rejectedGradeStr Vendor: ${_currentVendorUser!.name}.');

      VendorGrade? nextGrade = targetShipment.getNextGradeToAssignInOrder();

      if (nextGrade != null) {
        targetShipment.status = ShipmentStatus.awaitingVendorConfirmation;
        targetShipment.currentGradeToAssign = nextGrade;
        targetShipment.vendorName = null;
        targetShipment.assignedVendorId = null;
        targetShipment.confirmedByGrade = null;
        targetShipment.vehicleRegNo = null;
        _showSnackbar(
            'Forwarding ${targetShipment.shipmentNo} to next Grade: ${_getGradeText(nextGrade)}...');
      } else {
        targetShipment.status = ShipmentStatus.allGradesRejected;
        _showSnackbar(
            '${targetShipment.shipmentNo}: All assigned grades rejected. Requires dispatcher review.');
      }
      _updateDisplayedShipments(_filterController.text);
    });
  }

  String _getGradeText(VendorGrade? grade) {
    if (grade == null) return 'N/A';
    return grade.toString().split('.').last;
  }

  String _getStatusText(ShipmentStatus status, [VendorGrade? currentAssignGrade, VendorGrade? confirmedGrade]) {
    switch (status) {
      case ShipmentStatus.readyForBooking: return 'Ready for Booking';
      case ShipmentStatus.awaitingVendorConfirmation:
        return 'Awaiting Vendor (Grade ${_getGradeText(currentAssignGrade)})';
      case ShipmentStatus.confirmedByVendor:
        return 'Confirmed (Grade ${_getGradeText(confirmedGrade)})';
      case ShipmentStatus.allGradesRejected: return 'All Grades Rejected';
      case ShipmentStatus.bookingFinalized: return 'Booking Finalized';
      case ShipmentStatus.canceledByDispatcher: return 'Canceled';
    }
  }

  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.readyForBooking: return Colors.blueGrey;
      case ShipmentStatus.awaitingVendorConfirmation: return Colors.orange;
      case ShipmentStatus.confirmedByVendor: return Colors.green;
      case ShipmentStatus.allGradesRejected: return Colors.red.shade700;
      case ShipmentStatus.bookingFinalized: return Colors.purple;
      case ShipmentStatus.canceledByDispatcher: return Colors.amber.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('ระบบจองรถ - ${_currentUserRole == UserRole.dispatcher ? "Dispatcher" : "Vendor (Grade ${_currentVendorUser != null ? _getGradeText(_currentVendorUser!.grade) : 'Select'})"} View'),
        backgroundColor: colorScheme.primaryContainer,
        actions: [
          if (_currentUserRole == UserRole.vendor)
            PopupMenuButton<VendorGrade>(
              icon: const Icon(Icons.stairs_outlined),
              tooltip: "Switch Vendor Grade View (Simulated)",
              onSelected: _switchVendorGradeView,
              itemBuilder: (BuildContext context) => VendorGrade.values
                  .where((g) => g != VendorGrade.unassigned)
                  .map((grade) => PopupMenuItem<VendorGrade>(
                        value: grade,
                        child: Text('View as Grade ${_getGradeText(grade)}'),
                      )).toList(),
            ),
          PopupMenuButton<UserRole>(
            icon: const Icon(Icons.people_alt_outlined),
            onSelected: _switchUserRole,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<UserRole>>[
              const PopupMenuItem<UserRole>(value: UserRole.dispatcher, child: Text('Dispatcher View')),
              const PopupMenuItem<UserRole>(value: UserRole.vendor, child: Text('Vendor View')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_currentUserRole == UserRole.dispatcher) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
              child: TextField( /* ... Search Bar ... */
                controller: _filterController,
                decoration: InputDecoration(
                  labelText: 'Search Shipments...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () { _filterController.clear(); _updateDisplayedShipments(); },
                  ),
                ),
                onChanged: (query) => _updateDisplayedShipments(query),
              ),
            ),
            Padding( /* ... Filter Chips ... */
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Wrap(
                spacing: 8.0, runSpacing: 4.0,
                children: _filterableStatuses.map((status) {
                  final bool isSelected = _activeStatusFilters.contains(status);
                  return FilterChip(
                    label: Text(_getStatusText(status, null,null)), // Pass nulls as grade is not relevant for general status text here
                    selected: isSelected,
                    onSelected: (bool selected) => _toggleStatusFilter(status),
                    selectedColor: _getStatusColor(status).withAlpha((255 * 0.3).round()),
                    checkmarkColor: _getStatusColor(status),
                    side: isSelected ? BorderSide.none : BorderSide(color: Colors.grey.shade400),
                  );
                }).toList(),
              ),
            ),
          ],
          if (_currentUserRole == UserRole.vendor && _currentVendorUser == null)
             Expanded(child: Center(child: Text("Select a vendor grade to view tasks.", style: Theme.of(context).textTheme.titleMedium)))
          else if (_currentUserRole == UserRole.vendor && _displayedShipments.isEmpty)
            Expanded(child: Center(child: Text("No pending actions for Grade ${_getGradeText(_currentVendorUser?.grade)}.", style: Theme.of(context).textTheme.titleMedium)))
          else if (_currentUserRole == UserRole.vendor && _displayedShipments.isNotEmpty && _currentVendorUser != null)
             Padding(
               padding: const EdgeInsets.all(8.0),
               child: Text("Shipments awaiting Grade ${_getGradeText(_currentVendorUser!.grade)} confirmation:", style: Theme.of(context).textTheme.titleSmall,),
             ),
          Expanded(
            child: _displayedShipments.isEmpty && _currentUserRole == UserRole.dispatcher && (_filterController.text.isNotEmpty || _activeStatusFilters.isNotEmpty)
              ? Center(child: Text("No shipments match your current filters.", style: Theme.of(context).textTheme.titleMedium))
              : ListView.builder(
              itemCount: _displayedShipments.length,
              itemBuilder: (context, index) {
                final shipment = _displayedShipments[index];
                return ShipmentCard(
                  shipment: shipment,
                  currentUserRole: _currentUserRole,
                  currentVendorUser: _currentVendorUser,
                  availableVehicleTypes: _availableVehicleTypes,
                  onAction: (action, shipment, [dynamic value]) {
                    switch (action) {
                      case "setShippingType": setShipmentShippingType(shipment, value as String?); break;
                      case "requestBooking": requestVehicleBooking(shipment); break;
                      case "finalizeBooking": finalizeBooking(shipment); break;
                      case "cancelByDispatcher": cancelBookingByDispatcher(shipment); break;
                      case "confirmByVendor": confirmByVendor(shipment); break;
                      case "rejectByVendor": rejectByVendor(shipment); break;
                      case "manualAssign": _showSnackbar("Manual assignment for ${shipment.shipmentNo} not implemented."); break;
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final UserRole currentUserRole;
  final VendorUser? currentVendorUser;
  final List<String> availableVehicleTypes;
  final Function(String action, Shipment shipment, [dynamic value]) onAction;

  const ShipmentCard({
    super.key,
    required this.shipment,
    required this.currentUserRole,
    this.currentVendorUser,
    required this.availableVehicleTypes,
    required this.onAction,
  });

  String _getGradeTextForDisplay(VendorGrade? grade) {
    if (grade == null) return 'N/A';
    return grade.toString().split('.').last;
  }

   Color _getStatusColor(ShipmentStatus status, BuildContext context) {
     switch (status) {
      case ShipmentStatus.readyForBooking: return Colors.blueGrey;
      case ShipmentStatus.awaitingVendorConfirmation: return Colors.orange;
      case ShipmentStatus.confirmedByVendor: return Colors.green;
      case ShipmentStatus.allGradesRejected: return Colors.red.shade700;
      case ShipmentStatus.bookingFinalized: return Colors.purple;
      case ShipmentStatus.canceledByDispatcher: return Colors.amber.shade700;
    }
  }

   String _getStatusText(ShipmentStatus status, VendorGrade currentAssignGrade, VendorGrade? confirmedByGrade) {
     switch (status) {
      case ShipmentStatus.readyForBooking: return 'Ready for Booking';
      case ShipmentStatus.awaitingVendorConfirmation: return 'Awaiting (Grade ${_getGradeTextForDisplay(currentAssignGrade)})';
      case ShipmentStatus.confirmedByVendor: return 'Confirmed (Grade ${_getGradeTextForDisplay(confirmedByGrade)})';
      case ShipmentStatus.allGradesRejected: return 'All Grades Rejected';
      case ShipmentStatus.bookingFinalized: return 'Finalized';
      case ShipmentStatus.canceledByDispatcher: return 'Canceled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('S#: ${shipment.shipmentNo}',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: _getStatusColor(shipment.status, context).withAlpha((255 * 0.15).round()),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: _getStatusColor(shipment.status, context))),
                  child: Text(
                    _getStatusText(shipment.status, shipment.currentGradeToAssign, shipment.confirmedByGrade),
                    style: TextStyle(
                        color: _getStatusColor(shipment.status, context),
                        fontWeight: FontWeight.bold,
                        fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('DO: ${shipment.doNo ?? 'N/A'} | Route: ${shipment.route}', style: textTheme.bodySmall),
            Text('Type: ${shipment.shipmentType ?? 'N/A'}', style: textTheme.bodySmall),
            if (shipment.shippingType != null || currentUserRole == UserRole.dispatcher)
              Padding(
                padding: const EdgeInsets.only(top:2.0, bottom: 2.0),
                child: Text(
                  'Vehicle: ${shipment.shippingType ?? "Not selected"}',
                  style: TextStyle(
                    fontStyle: shipment.shippingType == null ? FontStyle.italic : FontStyle.normal,
                    color: shipment.shippingType == null ? Colors.grey.shade600 : textTheme.bodySmall?.color,
                    fontSize: textTheme.bodySmall?.fontSize
                  ),
                ),
              ),
            Text('Planned: ${shipment.plannedDateFormatted}', style: textTheme.bodySmall),
            if (currentUserRole == UserRole.dispatcher) ...[
              if (shipment.vendorName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Vendor: ${shipment.vendorName} (Grade ${_getGradeTextForDisplay(shipment.confirmedByGrade)})',
                      style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w500, fontSize: 11)),
                ),
              if (shipment.vehicleRegNo != null)
                Text('Veh.No: ${shipment.vehicleRegNo}',
                    style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w500, fontSize: 11)),
              if (shipment.status == ShipmentStatus.allGradesRejected && shipment.rejectionReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Last Rejection: ${shipment.rejectionReason}',
                      style: TextStyle(color: Colors.red.shade800, fontSize: 11)),
                ),
              if (shipment.status == ShipmentStatus.canceledByDispatcher && shipment.cancellationReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Canceled: ${shipment.cancellationReason}',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 11)),
                ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _buildActionButtons(context, colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    List<Widget> actionWidgets = [];
    ButtonStyle rButtonStyle = ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), textStyle: const TextStyle(fontSize: 12));
    ButtonStyle fButtonStyle = ElevatedButton.styleFrom(backgroundColor: colorScheme.secondary, foregroundColor: colorScheme.onSecondary, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), textStyle: const TextStyle(fontSize: 12));
    TextStyle vcTextStyle = TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12);
    TextStyle vrTextStyle = TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12);
    TextStyle dcTextStyle = TextStyle(color: Colors.orange.shade700, fontSize: 12);
    TextStyle disabledTextStyle = TextStyle(color: Colors.grey.shade600, fontSize: 12);

    if (currentUserRole == UserRole.dispatcher) {
      if (shipment.status == ShipmentStatus.readyForBooking) {
        actionWidgets.add(
          Expanded( /* ... Dropdown for vehicle type ... */
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Vehicle Type', hintStyle: const TextStyle(fontSize: 12), labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), isDense: true,
              ),
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color),
              value: shipment.shippingType, hint: const Text('Select Vehicle'),
              items: availableVehicleTypes.map((String value) => DropdownMenuItem<String>( value: value, child: Text(value, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (String? newValue) { onAction("setShippingType", shipment, newValue); },
            ),
          ),
        );
        actionWidgets.add(const SizedBox(width: 8));
        actionWidgets.add(ElevatedButton(
            style: rButtonStyle,
            onPressed: shipment.shippingType != null && shipment.shippingType!.isNotEmpty ? () => onAction("requestBooking", shipment) : null,
            child: const Text('Request')));
      }
      if (shipment.status == ShipmentStatus.confirmedByVendor) {
        actionWidgets.add(ElevatedButton(style: fButtonStyle, onPressed: () => onAction("finalizeBooking", shipment), child: const Text('Finalize')));
        actionWidgets.add(const SizedBox(width: 8));
        bool canCancel = shipment.plannedCheckIn.isAfter(DateTime.now());
        actionWidgets.add(TextButton(onPressed: canCancel ? () => onAction("cancelByDispatcher", shipment) : null,
            child: Text('Cancel', style: canCancel ? dcTextStyle : disabledTextStyle)));
      }
      if (shipment.status == ShipmentStatus.allGradesRejected) {
        actionWidgets.add(ElevatedButton(style: rButtonStyle, onPressed: () => onAction("requestBooking", shipment), child: const Text('Re-Attempt')));
        actionWidgets.add(const SizedBox(width: 8));
        actionWidgets.add(TextButton(onPressed: () => onAction("manualAssign", shipment), child: Text("Manual", style: TextStyle(color: colorScheme.tertiary, fontSize: 12))));
      }
    } else if (currentUserRole == UserRole.vendor && currentVendorUser != null) {
       if (shipment.status == ShipmentStatus.awaitingVendorConfirmation &&
           shipment.currentGradeToAssign == currentVendorUser!.grade) { // Key check
        actionWidgets.add(TextButton(onPressed: () => onAction("confirmByVendor", shipment),
            child: Text('Confirm (My Grade: ${_getGradeTextForDisplay(currentVendorUser!.grade)})', style: vcTextStyle)));
        actionWidgets.add(const SizedBox(width: 8));
        actionWidgets.add(TextButton(onPressed: () => onAction("rejectByVendor", shipment),
            child: Text('Reject (My Grade: ${_getGradeTextForDisplay(currentVendorUser!.grade)})', style: vrTextStyle)));
      }
    }
    if (currentUserRole == UserRole.dispatcher && shipment.status == ShipmentStatus.readyForBooking) {
      return Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: actionWidgets);
    }
    return Wrap(spacing: 6, runSpacing: 4, alignment: WrapAlignment.end, children: actionWidgets);
  }
}