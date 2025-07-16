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

  CarProfile({
    required this.carlicense,
    this.conid,
    this.cartype,
    this.cartypedes,
    this.remark,
    required this.stat,
  });

  factory CarProfile.fromJson(Map<String, dynamic> json) {
    return CarProfile(
      carlicense: json['carlicense'] ?? 'N/A License',
      conid: json['conid'],
      cartype: json['cartype'],
      cartypedes: json['cartypedes'],
      remark: json['remark'],
      stat: json['stat'] ?? 'N/A Stat',
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

// --- Shipment Model ---
class Shipment {
  final String shipid;
  final String? customerName;
  final String? provname;
  final String? shippoint;
  final String? cartype; // ประเภทรถ
  final String? cartypeDesc; // คำอธิบายประเภทรถ
  final int? quantity; // จำนวนรวม (อาจจะมาจากผลรวมของ details)
  final double? volumeCbm; // ปริมาตรรวม (อาจจะมาจากผลรวมของ details)
  bool isOnHold;
  final String? docstat;
  final List<ShipmentDetail> details; 
  final String? current_grade_to_assign;
  final Warehouse? warehouse;
  final ShipType? mshiptype;

  Shipment({
    required this.shipid,
    this.customerName,
    this.provname,
    this.cartype,
    this.cartypeDesc,
    this.quantity,
    this.volumeCbm,
    this.isOnHold = false,
    this.docstat,
    this.details = const [], 
    this.current_grade_to_assign,
    this.shippoint,
    this.warehouse,
    this.mshiptype,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    var detailListFromJson = json['details'] as List? ?? [];
    List<ShipmentDetail> parsedDetails = detailListFromJson
        .map((d) => ShipmentDetail.fromJson(d as Map<String, dynamic>))
        .toList();

    return Shipment(
      shipid: json['shipid'] ?? 'N/A ShipID',
      shippoint: json['shippoint'], 
      customerName: json['customer_name'],
      provname: json['provname'],
      cartype: json['cartype'],
      cartypeDesc: json['cartypeDesc'],
      quantity: json['quantity'],
      volumeCbm: json['volume_cbm'] != null ? double.tryParse(json['volume_cbm'].toString()) : null,
      isOnHold: json['is_on_hold'] ?? false,
      docstat: json['docstat'],
      details: parsedDetails,
      current_grade_to_assign: json['current_grade_to_assign'],
      mshiptype: json['mshiptype'] != null
               ? ShipType.fromJson(json['mshiptype'])
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