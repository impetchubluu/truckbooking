import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/api_models.dart';
import 'auth_service.dart';

class ApiService {
  final String _baseUrl = AuthService().baseUrl;

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    // Decode only if there is a body
    final responseData = response.body.isNotEmpty ? json.decode(response.body) : {};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': responseData};
    } else {
      print('API Error: Status ${response.statusCode}, Body: ${response.body}');
      return {'success': false, 'error': responseData['detail'] ?? 'An error occurred', 'isAuthError': response.statusCode == 401};
    }
  }

  Future<UserProfile> getUserProfile(String token) async {
    final uri = Uri.parse('$_baseUrl/users/me');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    final result = await _handleResponse(response);
    if (result['success'] == true) {
      return UserProfile.fromJson(result['data']);
    }
    throw result; // Throw the whole map to be caught in provider
  }

  Future<List<Warehouse>> getWarehouses(String token) async {
    final uri = Uri.parse('$_baseUrl/api/v1/master/warehouses');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    final result = await _handleResponse(response);
    if (result['success'] == true) {
      final List<dynamic> data = result['data'] ?? [];
      return data.map((json) => Warehouse.fromJson(json)).toList();
    }
    throw Exception(result['error']);
  }

  Future<List<BookingRound>> getBookingRounds(String token, DateTime date, String warehouseCode) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final uri = Uri.parse('$_baseUrl/api/v1/booking-rounds?round_date=$dateString&warehouse_code=$warehouseCode');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    final result = await _handleResponse(response);
    if (result['success'] == true) {
      final List<dynamic> data = result['data'] ?? [];
      return data.map((json) => BookingRound.fromJson(json)).toList();
    }
    throw Exception(result['error']);
  }

  Future<List<Shipment>> getUnassignedShipments(String token, DateTime date, String shippoint) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final uri = Uri.parse('$_baseUrl/api/v1/shipments/unassigned?apmdate=$dateString&shippoint=$shippoint');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    final result = await _handleResponse(response);
    if (result['success'] == true) {
      final List<dynamic> data = result['data'] ?? [];
      return data.map((json) => Shipment.fromJson(json)).toList();
    }
    throw Exception(result['error']);
  }

  Future<Shipment> holdShipment(String token, String shipId, bool hold) async {
    final uri = Uri.parse('$_baseUrl/api/v1/shipments/$shipId/hold');
    final response = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'hold': hold}),
    );
    final result = await _handleResponse(response);
    if (result['success'] == true) {
      return Shipment.fromJson(result['data']);
    }
    throw Exception(result['error']);
  }
  Future<List<Shipment>> getShipments(String token, {String? docstat}) async {
    var uri = Uri.parse('$_baseUrl/api/v1/shipments/'); // Endpoint หลัก
    if (docstat != null) {
       uri = uri.replace(queryParameters: {'docstat': docstat});
    }

    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    final result = await _handleResponse(response);

    if (result['success']) {
      final List<dynamic> data = result['data'] ?? [];
      return data.map((json) => Shipment.fromJson(json)).toList();
    }
    throw Exception(result['error']);
  }
  Future<Shipment> getShipmentDetails(String token, String shipId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/shipments/$shipId');
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    final result = await _handleResponse(response);
    if (result['success'] == true) {
      return Shipment.fromJson(result['data']);
    }
    throw Exception(result['error']);
  }
  Future<Shipment> requestBooking(String token, String shipId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/shipments/request-booking');
    print('ApiService: Requesting booking for shipId: $shipId');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'shipid': shipId}),
    );

    final result = await _handleResponse(response);
    if (result['success']) {
      return Shipment.fromJson(result['data']);
    }
    // Throw an exception with a detailed error message
    throw Exception(result['error'] ?? 'Failed to request booking');
  }
   Future<void> updateFCMToken(String userAccessToken, String fcmToken) async {
    final uri = Uri.parse('$_baseUrl/users/update-fcm-token');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $userAccessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'fcm_token': fcmToken}),
    );

    // เราอาจจะไม่ต้องสนใจ Response มากนักถ้ามันสำเร็จ
    if (response.statusCode != 200) {
      // แต่ถ้าไม่สำเร็จ ควรจะ Throw Exception
      final result = await _handleResponse(response);
      throw Exception(result['error']);
    }
  }
}