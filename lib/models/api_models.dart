// ignore_for_file: non_constant_identifier_names


import 'package:flutter/material.dart';

// --- Car Model ---
class CarProfile {
  final String carlicense;
  final String? conid;
  final String? cartype;
  final String? cartypedes;
  final String? remark;
  final String stat;
  final DateTime? will_be_available_at; // วันที่จะพร้อมใช้งาน
  CarProfile({
    required this.carlicense,
    this.conid,
    this.cartype,
    this.cartypedes,
    this.remark,
    required this.stat,
    this.will_be_available_at, // วันที่จะพร้อมใช้งาน
  });

  factory CarProfile.fromJson(Map<String, dynamic> json) {
    return CarProfile(
      carlicense: json['carlicense'] ?? 'N/A License',
      conid: json['conid'],
      cartype: json['cartype'],
      cartypedes: json['cartypedes'],
      remark: json['remark'],
      stat: json['stat'] ?? 'N/A Stat',
      will_be_available_at: json['will_be_available_at'] != null
          ? DateTime.tryParse(json['will_be_available_at'])
          : null, // แปลงวันที่จะพร้อมใช้งานเป็น DateTime ถ้าไม่เป็น null
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'carlicense': carlicense,
      'conid': conid,
      'cartype': cartype,
      'cartypedes': cartypedes,
      'remark': remark,
      'stat': stat,
    };
  }
  
}
class VendorProfile {
  final String vencode;
  final String venname;
  final String grade;
  final List<CarProfile> cars;

  VendorProfile({
    required this.vencode,
    required this.venname,
    required this.grade,
    this.cars = const [], // ให้ค่า default เป็น List ว่าง
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    // ดึงข้อมูล list ของรถออกมา
    var carListFromJson = json['cars'] as List? ?? []; // ป้องกันกรณี cars เป็น null
    
    // แปลง list ของ JSON object ให้เป็น List ของ CarProfile object
    List<CarProfile> parsedCars = carListFromJson
        .map((carJson) => CarProfile.fromJson(carJson as Map<String, dynamic>))
        .toList();

    return VendorProfile(
      vencode: json['vencode'] ?? 'N/A',
      venname: json['venname'] ?? 'Unknown Vendor',
      grade: json['grade'] ?? 'N/A',
      cars: parsedCars,
    );
  }
}
class ShipType {
  final String cartype;
  final String cartypedes;

  ShipType({required this.cartype, required this.cartypedes});

  factory ShipType.fromJson(Map<String, dynamic> json) {
    return ShipType(
      cartype: json['cartype'] ?? 'N/A',
      cartypedes: json['cartypedes'] ?? 'Unknown Type',
    );
  }
}
// --- User Profile Model ---
class UserProfile {
  final int id;
  final String username;
  final String role;
  final String? displayName;
  final bool isActive;
  final String? vencode;
  final String? grade;
  final List<CarProfile> cars;

  UserProfile({
    required this.id,
    required this.username,
    required this.role,
    this.displayName,
    required this.isActive,
    this.vencode,
    this.grade,
    this.cars = const [],
  });

  // ฟังก์ชัน fromJson เพื่อแปลงข้อมูลจาก JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    var carListFromJson = json['cars'] as List?;
    List<CarProfile> carsList = carListFromJson?.map((carJson) => CarProfile.fromJson(carJson as Map<String, dynamic>)).toList() ?? [];
    return UserProfile(
      id: json['id'] ?? 0,
      username: json['username'] ?? 'N/A Username',
      role: json['role'] ?? 'unknown',
      displayName: json['display_name'],
      isActive: json['is_active'] ?? false,
      vencode: json['vencode'],
      grade: json['grade'],
      cars: carsList,
    );
  }

  // ฟังก์ชัน toJson เพื่อแปลง UserProfile กลับเป็น JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'display_name': displayName,
      'is_active': isActive,
      'vencode': vencode,
      'grade': grade,
      'cars': cars.map((car) => car.toJson()).toList(),
    };
  }
}


// --- Warehouse Model ---
class Warehouse {
  final String code;
  final String name;

  Warehouse({required this.code, required this.name});

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      code: json['warehouse_code'] ?? 'N/A',
      name: json['warehouse_name'] ?? 'Unknown Warehouse',
    );
  }
}
class MLeadTime {
  final String route;
  final String provth;
  final String? routedes;
  final String? proven;
  final String? zone;
  final String? zonedes;
  final double leadTime;

  MLeadTime({
    required this.route,
    required this.provth,
    this.routedes,
    this.proven,
    this.zone,
    this.zonedes,
    required this.leadTime,
  });

  factory MLeadTime.fromJson(Map<String, dynamic> json) {
    return MLeadTime(
      route: json['route'] ?? '',
      provth: json['provth'] ?? '',
      routedes: json['routedes'],
      proven: json['proven'],
      zone: json['zone'],
      zonedes: json['zonedes'],
      leadTime: json['leadtime'] ?? 0, 
    );
  }
}
class MProvince {
  final int province;
  final String provname;

  MProvince({required this.province, required this.provname});

  factory MProvince.fromJson(Map<String, dynamic> json) {
    return MProvince(
      province: json['province'] ?? 0,
      provname: json['provname'] ?? 'N/A',
    );
  }
}
class MVendor {
  final String vencode;
  final String venname;
  final String grade;
  // คุณสามารถเพิ่ม field อื่นๆ ของ vendor ได้ตามต้องการ

  MVendor({
    required this.vencode,
    required this.venname,
    required this.grade,
  });

  factory MVendor.fromJson(Map<String, dynamic> json) {
    return MVendor(
      vencode: json['vencode'] ?? 'N/A',
      venname: json['venname'] ?? 'Unknown Vendor',
      grade: json['grade'] ?? 'N/A',
    );
  }
}
// --- Shipment Model ---
class Shipment {
  final String shipid;
  final String? customerName;
  final int? province;
  final MProvince? mprovince;
  final String? shippoint;
  final String? cartype;
  final String? vencode;
  final String? carlicense; // ประเภทรถ
  final String? cartypeDesc; // คำอธิบายประเภทรถ
  final int? quantity; // จำนวนรวม (อาจจะมาจากผลรวมของ details)
  final double? volumeCbm; // ปริมาตรรวม (อาจจะมาจากผลรวมของ details)
  bool isOnHold;
  final String? docstat;
  final String? route;
  final MLeadTime? mLeadTime;
  final List<ShipmentDetail> details; 
  final String? current_grade_to_assign;
  final Warehouse? warehouse;
  final ShipType? mshiptype;
  final DateTime? assigned_at;
  final DateTime? apmdate;
  final DateTime? chdate; 
  final DateTime? crdate; 
  final MVendor? mvendor;
  Shipment({
    required this.shipid,
    this.customerName,
    this.province,
    this.mprovince,
    this.cartype,
    this.vencode,
    this.carlicense,
    this.cartypeDesc,
    this.quantity,
    this.volumeCbm,
    this.isOnHold = false,
    this.docstat,
    this.route,
    this.mLeadTime,
    this.details = const [], 
    this.current_grade_to_assign,
    this.shippoint,
    this.warehouse,
    this.mshiptype,
    this.assigned_at,
    this.apmdate, // วันที่นัดรับ
    this.chdate,
    this.crdate,
    this.mvendor,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    var detailListFromJson = json['details'] as List? ?? [];
    List<ShipmentDetail> parsedDetails = detailListFromJson
        .map((d) => ShipmentDetail.fromJson(d as Map<String, dynamic>))
        .toList();
    final String? assignedAtString = json['assigned_at'];
  DateTime? assignedAtUtc;
   if (assignedAtString != null) {
    // --- จุดแก้ไขสำคัญ ---
    // ต่อท้ายด้วย 'Z' เพื่อบอกให้ Dart รู้ว่านี่คือเวลา UTC
    assignedAtUtc = DateTime.parse('${assignedAtString}Z'); 
  }
    return Shipment(
      shipid: json['shipid'] ?? 'N/A ShipID',
      shippoint: json['shippoint'], 
      customerName: json['customer_name'],
      province: json['province'],
      mprovince: json['mprovince'] != null
               ? MProvince.fromJson(json['mprovince'])
               : null,
      cartype: json['cartype'],
      vencode: json['vencode'],
      carlicense: json['carlicense'],
      cartypeDesc: json['cartypeDesc'],
      quantity: json['quantity'],
      volumeCbm: json['volume_cbm'] != null ? double.tryParse(json['volume_cbm'].toString()) : null,
      isOnHold: json['is_on_hold'] ?? false,
      docstat: json['docstat'],
      route: json['route'],
       mLeadTime: json['mleadtime'] != null
               ? MLeadTime.fromJson(json['mleadtime'])
               : null,
      details: parsedDetails,
      current_grade_to_assign: json['current_grade_to_assign'],
      mshiptype: json['mshiptype'] != null
               ? ShipType.fromJson(json['mshiptype'])
               : null,
      assigned_at:assignedAtUtc,
      apmdate: json['apmdate'] != null
          ? DateTime.tryParse(json['apmdate'])
          : null, // แปลงวันที่นัดรับเป็น DateTime
          
      chdate: json['chdate'] != null
          ? DateTime.tryParse(json['chdate'])
          : null, // แปลงวันที่เปลี่ยนแปลงสถานะเป็น DateTime
      crdate: json['crdate'] != null
          ? DateTime.tryParse(json['crdate'])
          : null, // แปลงวันที่สร้างเป็น DateTime
      mvendor: json['mvendor'] != null
               ? MVendor.fromJson(json['mvendor'])
               : null,
    );
    

  }
}
// --- Booking Round Model ---
class BookingRound {
  final int id;
  final String name;
  final TimeOfDay? time;
  final List<Shipment> shipments;

  BookingRound({
    required this.id,
    required this.name,
    this.time,
    this.shipments = const [],
  });

  factory BookingRound.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parsedTime; 
    parsedTime = TimeOfDay.now();
    if (json['round_time'] != null && json['round_time'] is String) {
      final parts = json['round_time'].split(':');
      if (parts.length >= 2) {
        parsedTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0);
      }
    }
    var shipmentList = json['shipments'] as List? ?? [];
    return BookingRound(
      id: json['id'] ?? 0,
      name: json['round_name'] ?? 'N/A Round',
      time: parsedTime,
      shipments: shipmentList.map((s) => Shipment.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}
class ShipmentDetail {
  final String doid; // doidPrimary จาก DB
  final String shipid;
  final DateTime dlvdate; // ใช้ DateTime เพื่อจัดการวันที่ได้ง่าย
  final String cusid;
  final String cusname;
  final String route;
  final String? routedes; // อาจจะเป็น null
  final String province;
  final double volumn;

  ShipmentDetail({
    required this.doid,
    required this.shipid,
    required this.dlvdate,
    required this.cusid,
    required this.cusname,
    required this.route,
    this.routedes,
    required this.province,
    required this.volumn,
  });

  // factory constructor สำหรับแปลง JSON ที่ได้จาก API
  factory ShipmentDetail.fromJson(Map<String, dynamic> json) {
    return ShipmentDetail(
      // ***สำคัญ: key ใน json['key'] ต้องตรงกับที่ Backend ส่งมา***
      doid: json['doid'] ?? 'N/A', 
      shipid: json['shipid'] ?? 'N/A',
      // แปลง String date (เช่น '2024-12-25') เป็น DateTime object
      dlvdate: DateTime.tryParse(json['dlvdate'] ?? '') ?? DateTime.now(),
      cusid: json['cusid'] ?? 'N/A',
      cusname: json['cusname'] ?? 'N/A',
      route: json['route'] ?? 'N/A',
      routedes: json['routedes'], // รับค่า null ได้
      province: json['province'] ?? 'N/A',
      // แปลงค่าที่อาจจะเป็น int หรือ double ให้เป็น double
      volumn: (json['volumn'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
class MasterBookingRound {
  final TimeOfDay time;
  final String? name;

  MasterBookingRound({required this.time, this.name});

  factory MasterBookingRound.fromJson(Map<String, dynamic> json) {
    TimeOfDay parsedTime = TimeOfDay.now();
    if (json['round_time'] != null && json['round_time'] is String) {
      final parts = json['round_time'].split(':');
      if (parts.length >= 2) {
        parsedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }
    return MasterBookingRound(
      time: parsedTime,
      name: json['round_name'],
    );
  }
}