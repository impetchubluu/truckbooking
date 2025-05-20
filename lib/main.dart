import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Enums ---
enum ShipmentStatus {
  readyForBooking,
  awaitingVendorConfirmation,
  confirmedByVendor,
  allTiersRejected,
  bookingFinalized,
  canceledByDispatcher,
}

enum UserRole { dispatcher, vendor }

// --- Data Model (Shipment class remains the same) ---
class Shipment {
  final String shipmentNo;
  String? shipmentType;
  String? shippingType;
  String? doNo;
  final String route;
  final DateTime plannedCheckIn;
  String? shippingConType;
  String? vendorName;
  String? vehicleRegNo;
  ShipmentStatus status;
  String? rejectionReason;
  String? cancellationReason;
  int currentVendorTier;
  final int maxVendorTiers;

  Shipment({
    required this.shipmentNo,
    this.shipmentType,
    this.shippingType,
    this.doNo,
    required this.route,
    required this.plannedCheckIn,
    this.shippingConType,
    this.vendorName,
    this.vehicleRegNo,
    this.status = ShipmentStatus.readyForBooking,
    this.rejectionReason,
    this.cancellationReason,
    this.currentVendorTier = 1,
    this.maxVendorTiers = 3,
  });

  String get plannedDateFormatted =>
      DateFormat('yyyy-MM-dd HH:mm').format(plannedCheckIn.toLocal());
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
        colorSchemeSeed: Colors.lightBlueAccent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const ShipmentPage(), // Ensure ShipmentPage class is defined
    );
  }
}

// --- Shipment Page State Management ---
// Ensure this class is defined correctly
class ShipmentPage extends StatefulWidget {
  const ShipmentPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ShipmentPageState createState() => _ShipmentPageState();
}

class _ShipmentPageState extends State<ShipmentPage> {
  UserRole _currentUserRole = UserRole.dispatcher;
  final List<String> _availableVehicleTypes = [
    'รถกระบะ', 'รถกระบะตู้ทึบ', 'รถบรรทุก 4 ล้อ', 'รถบรรทุก 6 ล้อ',
    'รถบรรทุก 10 ล้อ', 'รถพ่วง', 'รถตู้เย็น', 'Other',
  ];
  // FIX: prefer_final_fields
  final List<Shipment> _allShipments = [
    Shipment(shipmentNo: 'SHP001', route: 'Route A - North', plannedCheckIn: DateTime.now().add(const Duration(days: 5, hours: 10)), shipmentType: 'FTL', doNo: 'DO-1001', shippingConType: '20'),
    Shipment(shipmentNo: 'SHP002', route: 'Route B - East', plannedCheckIn: DateTime.now().add(const Duration(days: 6, hours: 14)), shipmentType: 'LTL', shippingType: 'รถกระบะตู้ทึบ', doNo: 'DO-1002', shippingConType: '20'),
    Shipment(shipmentNo: 'SHP003', route: 'Route C - West', plannedCheckIn: DateTime.now().add(const Duration(days: 7, hours: 9)), shipmentType: 'FTL', shippingType: 'รถบรรทุก 10 ล้อ', doNo: 'DO-1003', shippingConType: '20', status: ShipmentStatus.awaitingVendorConfirmation, currentVendorTier: 1),
    Shipment(shipmentNo: 'SHP004', route: 'Route D - South', plannedCheckIn: DateTime.now().add(const Duration(days: 8, hours: 16)), shipmentType: 'FTL', shippingType: 'รถพ่วง', doNo: 'DO-1004', shippingConType: '20', status: ShipmentStatus.confirmedByVendor, vendorName: 'GoodTransporter (Tier 1)', vehicleRegNo: 'กท-1234'),
    Shipment(shipmentNo: 'SHP005', route: 'Route E - Central', plannedCheckIn: DateTime.now().add(const Duration(days: 2, hours: 11)), shipmentType: 'FTL', doNo: 'DO-1005', shippingConType: '20', status: ShipmentStatus.readyForBooking, maxVendorTiers: 2),
    Shipment(shipmentNo: 'SHP006', route: 'Route F - NorthEast', plannedCheckIn: DateTime.now().add(const Duration(days: 3, hours: 15)), shipmentType: 'FTL', shippingType: 'รถบรรทุก 6 ล้อ', doNo: 'DO-1006', shippingConType: '20', status: ShipmentStatus.allTiersRejected, rejectionReason: "All vendors busy", currentVendorTier: 4, maxVendorTiers: 3),
    Shipment(shipmentNo: 'SHP007', route: 'Route G - SouthWest', plannedCheckIn: DateTime.now().add(const Duration(days: 1, hours: 9)), shipmentType: 'LTL', shippingType: 'รถกระบะ', doNo: 'DO-1007', shippingConType: '20', status: ShipmentStatus.bookingFinalized, vendorName: "FastDelivery Co.", vehicleRegNo: "BD-5678"),
    Shipment(shipmentNo: 'SHP008', route: 'Route H - Metro', plannedCheckIn: DateTime.now().add(const Duration(days: 4, hours: 13)), shipmentType: 'FTL', shippingType: 'รถบรรทุก 10 ล้อ', doNo: 'DO-1008', shippingConType: '20', status: ShipmentStatus.canceledByDispatcher, cancellationReason: "Customer request"),
  ];

  List<Shipment> _displayedShipments = [];
  final TextEditingController _filterController = TextEditingController();
  // FIX: prefer_final_fields
  final Set<ShipmentStatus> _activeStatusFilters = {};

  final List<ShipmentStatus> _filterableStatuses = [
    ShipmentStatus.readyForBooking,
    ShipmentStatus.awaitingVendorConfirmation,
    ShipmentStatus.confirmedByVendor,
    ShipmentStatus.allTiersRejected,
    ShipmentStatus.bookingFinalized,
    ShipmentStatus.canceledByDispatcher,
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

      if (_currentUserRole == UserRole.vendor) {
        _displayedShipments = tempFiltered
            .where((s) => s.status == ShipmentStatus.awaitingVendorConfirmation)
            .toList();
      } else {
        _displayedShipments = tempFiltered;
      }
    });
  }

  void _toggleStatusFilter(ShipmentStatus status) {
    setState(() {
      if (_activeStatusFilters.contains(status)) {
        _activeStatusFilters.remove(status);
      } else {
        _activeStatusFilters.add(status);
      }
      _updateDisplayedShipments(_filterController.text);
    });
  }

  void _switchUserRole(UserRole? newRole) {
    if (newRole != null) {
      setState(() {
        _currentUserRole = newRole;
        _filterController.clear();
        _activeStatusFilters.clear();
        _updateDisplayedShipments();
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void setShipmentShippingType(Shipment shipment, String? newType) {
     setState(() {
      final originalShipment = _allShipments.firstWhere((s) => s.shipmentNo == shipment.shipmentNo);
      originalShipment.shippingType = newType;
      _updateDisplayedShipments(_filterController.text);
    });
  }

  void requestVehicleBooking(Shipment shipment) {
     if (shipment.shippingType == null || shipment.shippingType!.isEmpty) {
      _showSnackbar('Please select a vehicle type (ประเภทรถ) before requesting booking.');
      return;
    }
    setState(() {
      shipment.status = ShipmentStatus.awaitingVendorConfirmation;
      shipment.currentVendorTier = 1;
      shipment.vendorName = null;
      shipment.vehicleRegNo = null;
      shipment.rejectionReason = null;
      _showSnackbar(
          'Requesting ${shipment.shippingType} for ${shipment.shipmentNo} (Tier ${shipment.currentVendorTier})...');
      _updateDisplayedShipments(_filterController.text);
    });
  }

  void finalizeBooking(Shipment shipment) {
     setState(() {
      shipment.status = ShipmentStatus.bookingFinalized;
      _showSnackbar(
          'Booking for ${shipment.shipmentNo} finalized with ${shipment.vendorName}. Data to DB/SAP.');
      _updateDisplayedShipments(_filterController.text);
    });
  }

  void cancelBookingByDispatcher(Shipment shipment) {
    setState(() {
      shipment.status = ShipmentStatus.canceledByDispatcher;
      shipment.cancellationReason = "Cancelled by Dispatcher";
      _showSnackbar(
          'Booking for ${shipment.shipmentNo} canceled. Vendor ${shipment.vendorName ?? ''} notified.');
      _updateDisplayedShipments(_filterController.text);
    });
  }

  void confirmByVendor(Shipment shipment) {
    setState(() {
      shipment.status = ShipmentStatus.confirmedByVendor;
      shipment.vendorName = "Vendor Tier ${shipment.currentVendorTier} Ltd.";
      shipment.vehicleRegNo = "VT${shipment.currentVendorTier}-${UniqueKey().toString().substring(0, 4).toUpperCase()}";
      _showSnackbar(
          '${shipment.shipmentNo} confirmed by ${shipment.vendorName}.');
      _updateDisplayedShipments(_filterController.text);
    });
  }

  void rejectByVendor(Shipment shipment) {
    setState(() {
      String oldVendorName = "Vendor Tier ${shipment.currentVendorTier}";
      shipment.rejectionReason = "Vehicle unavailable by $oldVendorName";
      _showSnackbar('${shipment.shipmentNo} rejected by $oldVendorName.');

      shipment.currentVendorTier++;

      if (shipment.currentVendorTier <= shipment.maxVendorTiers) {
        shipment.status = ShipmentStatus.awaitingVendorConfirmation;
        shipment.vendorName = null;
        shipment.vehicleRegNo = null;
        _showSnackbar(
            'Forwarding ${shipment.shipmentNo} to next vendor tier (${shipment.currentVendorTier}/${shipment.maxVendorTiers})...');
      } else {
        shipment.status = ShipmentStatus.allTiersRejected;
        _showSnackbar(
            '${shipment.shipmentNo}: All ${shipment.maxVendorTiers} vendor tiers rejected.');
      }
      _updateDisplayedShipments(_filterController.text);
    });
  }

  String _getStatusText(ShipmentStatus status, [int? currentTier, int? maxTiers]) {
    switch (status) {
      case ShipmentStatus.readyForBooking: return 'Ready for Booking';
      case ShipmentStatus.awaitingVendorConfirmation:
        if (currentTier != null && maxTiers != null) {
          return 'Awaiting Vendor (Tier $currentTier/$maxTiers)';
        }
        return 'Awaiting Vendor';
      case ShipmentStatus.confirmedByVendor: return 'Confirmed by Vendor';
      case ShipmentStatus.allTiersRejected: return 'All Tiers Rejected';
      case ShipmentStatus.bookingFinalized: return 'Booking Finalized';
      case ShipmentStatus.canceledByDispatcher: return 'Canceled';
    }
  }

  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.readyForBooking: return Colors.blueGrey;
      case ShipmentStatus.awaitingVendorConfirmation: return Colors.orange;
      case ShipmentStatus.confirmedByVendor: return Colors.green;
      case ShipmentStatus.allTiersRejected: return Colors.red.shade700;
      case ShipmentStatus.bookingFinalized: return Colors.purple;
      case ShipmentStatus.canceledByDispatcher: return Colors.amber.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'ระบบจองรถ - ${_currentUserRole == UserRole.dispatcher ? "Dispatcher View" : "Vendor View"}'),
        backgroundColor: colorScheme.primaryContainer,
        actions: [
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
              child: TextField(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _filterableStatuses.map((status) {
                  final bool isSelected = _activeStatusFilters.contains(status);
                  return FilterChip(
                    label: Text(_getStatusText(status)),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      _toggleStatusFilter(status);
                    },
                    // FIX: deprecated_member_use
                    selectedColor: _getStatusColor(status).withAlpha((255 * 0.3).round()),
                    checkmarkColor: _getStatusColor(status),
                    side: isSelected ? BorderSide.none : BorderSide(color: Colors.grey.shade400),
                  );
                }).toList(),
              ),
            ),
          ],
           if (_currentUserRole == UserRole.vendor && _displayedShipments.isEmpty)
            Expanded(child: Center(child: Text("No pending actions for you.", style: Theme.of(context).textTheme.titleMedium)))
          else if (_currentUserRole == UserRole.vendor && _displayedShipments.isNotEmpty)
             Padding(
               padding: const EdgeInsets.all(8.0),
               child: Text("Shipments awaiting your confirmation (Tier ${_displayedShipments.first.currentVendorTier}):", style: Theme.of(context).textTheme.titleSmall,),
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
  final List<String> availableVehicleTypes;
  final Function(String action, Shipment shipment, [dynamic value]) onAction;

  const ShipmentCard({
    super.key,
    required this.shipment,
    required this.currentUserRole,
    required this.availableVehicleTypes,
    required this.onAction,
  });

   Color _getStatusColor(ShipmentStatus status, BuildContext context) {
     switch (status) {
      case ShipmentStatus.readyForBooking: return Colors.blueGrey;
      case ShipmentStatus.awaitingVendorConfirmation: return Colors.orange;
      case ShipmentStatus.confirmedByVendor: return Colors.green;
      case ShipmentStatus.allTiersRejected: return Colors.red.shade700;
      case ShipmentStatus.bookingFinalized: return Colors.purple;
      case ShipmentStatus.canceledByDispatcher: return Colors.amber.shade700;
    }
  }

   String _getStatusText(ShipmentStatus status, int currentTier, int maxTiers) {
     switch (status) {
      case ShipmentStatus.readyForBooking: return 'Ready for Booking';
      case ShipmentStatus.awaitingVendorConfirmation: return 'Awaiting Vendor (T$currentTier/$maxTiers)';
      case ShipmentStatus.confirmedByVendor: return 'Confirmed';
      case ShipmentStatus.allTiersRejected: return 'All Tiers Rejected';
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
                      // FIX: deprecated_member_use
                      color: _getStatusColor(shipment.status, context).withAlpha((255 * 0.15).round()),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: _getStatusColor(shipment.status, context))),
                  child: Text(
                    _getStatusText(shipment.status, shipment.currentVendorTier, shipment.maxVendorTiers),
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
                  child: Text('Vendor: ${shipment.vendorName}',
                      style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w500, fontSize: 11)),
                ),
              if (shipment.vehicleRegNo != null)
                Text('Veh.No: ${shipment.vehicleRegNo}',
                    style: TextStyle(color: Colors.teal.shade600, fontWeight: FontWeight.w500, fontSize: 11)),
              if (shipment.status == ShipmentStatus.allTiersRejected && shipment.rejectionReason != null)
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
    // FIX: non_constant_identifier_names
    ButtonStyle rButtonStyle = ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), textStyle: const TextStyle(fontSize: 12));
    ButtonStyle fButtonStyle = ElevatedButton.styleFrom(backgroundColor: colorScheme.secondary, foregroundColor: colorScheme.onSecondary, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), textStyle: const TextStyle(fontSize: 12));
    TextStyle vcTextStyle = TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12);
    TextStyle vrTextStyle = TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12);
    TextStyle dcTextStyle = TextStyle(color: Colors.orange.shade700, fontSize: 12);
    TextStyle disabledTextStyle = TextStyle(color: Colors.grey.shade600, fontSize: 12);

    if (currentUserRole == UserRole.dispatcher) {
      if (shipment.status == ShipmentStatus.readyForBooking) {
        actionWidgets.add(
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Vehicle Type',
                hintStyle: const TextStyle(fontSize: 12),
                labelStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                isDense: true,
              ),
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyLarge?.color),
              value: shipment.shippingType,
              hint: const Text('Select Vehicle'),
              items: availableVehicleTypes.map((String value) {
                return DropdownMenuItem<String>( value: value, child: Text(value, overflow: TextOverflow.ellipsis));
              }).toList(),
              onChanged: (String? newValue) { onAction("setShippingType", shipment, newValue); },
            ),
          ),
        );
        actionWidgets.add(const SizedBox(width: 8));
        actionWidgets.add(ElevatedButton(
            style: rButtonStyle, // Use corrected name
            onPressed: shipment.shippingType != null && shipment.shippingType!.isNotEmpty
                ? () => onAction("requestBooking", shipment) : null,
            child: const Text('Request')));
      }
      if (shipment.status == ShipmentStatus.confirmedByVendor) {
        actionWidgets.add(ElevatedButton(style: fButtonStyle, onPressed: () => onAction("finalizeBooking", shipment), child: const Text('Finalize'))); // Use corrected name
        actionWidgets.add(const SizedBox(width: 8));
        bool canCancel = shipment.plannedCheckIn.isAfter(DateTime.now());
        actionWidgets.add(TextButton(onPressed: canCancel ? () => onAction("cancelByDispatcher", shipment) : null,
            child: Text('Cancel', style: canCancel ? dcTextStyle : disabledTextStyle))); // Use corrected names
      }
      if (shipment.status == ShipmentStatus.allTiersRejected) {
        actionWidgets.add(ElevatedButton(style: rButtonStyle, onPressed: () => onAction("requestBooking", shipment), child: const Text('Re-Attempt'))); // Use corrected name
        actionWidgets.add(const SizedBox(width: 8));
        actionWidgets.add(TextButton(onPressed: () => onAction("manualAssign", shipment), child: Text("Manual", style: TextStyle(color: colorScheme.tertiary, fontSize: 12))));
      }
    } else if (currentUserRole == UserRole.vendor) {
       if (shipment.status == ShipmentStatus.awaitingVendorConfirmation) {
        actionWidgets.add(TextButton(onPressed: () => onAction("confirmByVendor", shipment),
            child: Text('Confirm (T${shipment.currentVendorTier})', style: vcTextStyle))); // Use corrected name
        actionWidgets.add(const SizedBox(width: 8));
        actionWidgets.add(TextButton(onPressed: () => onAction("rejectByVendor", shipment),
            child: Text('Reject (T${shipment.currentVendorTier})', style: vrTextStyle))); // Use corrected name
      }
    }
    if (currentUserRole == UserRole.dispatcher && shipment.status == ShipmentStatus.readyForBooking) {
      return Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: actionWidgets);
    }
    return Wrap(spacing: 6, runSpacing: 4, alignment: WrapAlignment.end, children: actionWidgets);
  }
}