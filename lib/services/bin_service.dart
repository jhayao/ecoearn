import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class BinService {
  static const String baseUrl = 'http://10.5.0.2:3000/api';
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  /// Activate bin after QR scan
  Future<Map<String, dynamic>> activateBin({
    required String binId,
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Get fresh auth token
      final token = await _getCurrentUserToken();
      if (token != null) {
        setAuthToken(token);
      }

      print('🔵 Activating bin: $binId');
      print('🔵 API URL: $baseUrl/bins/activate');

      final response = await http.post(
        Uri.parse('$baseUrl/bins/activate'),
        headers: _headers,
        body: jsonEncode({
          'binId': binId,
          'userId': userId,
          'scannedAt': DateTime.now().toIso8601String(),
          'location': {
            'latitude': latitude,
            'longitude': longitude,
          },
        }),
      );

      print('🔵 Response Status: ${response.statusCode}');
      print('🔵 Response Headers: ${response.headers}');
      print('🔵 Response Body: ${response.body}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        throw Exception('Server returned empty response');
      }

      // Try to decode JSON
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (jsonError) {
        print('❌ JSON Parse Error: $jsonError');
        print('❌ Raw Response: ${response.body}');
        throw Exception('Invalid response from server: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');
      }

      if (response.statusCode == 200 && data['success'] == true) {
        final sessionId = data['data']['sessionId'];
        
        // Send to ESP32-CAM via Bluetooth (implement this later)
        final command = 'ACTIVATE_BIN:$userId:$sessionId';
        await _sendToESP32CAM(command);
        
        return data;
      } else if (response.statusCode == 409) {
        throw Exception('Bin is already in use by another user');
      } else if (response.statusCode == 404) {
        throw Exception('Bin not found');
      } else {
        throw Exception(data['error'] ?? 'Failed to activate bin');
      }
    } catch (e) {
      print('❌ Error in activateBin: $e');
      rethrow;
    }
  }

  /// Deactivate bin when user finishes recycling
  Future<Map<String, dynamic>> deactivateBin({
    required String binId,
    required String userId,
    required String sessionId,
  }) async {
    try {
      // Get fresh auth token
      final token = await _getCurrentUserToken();
      if (token != null) {
        setAuthToken(token);
      }

      print('🟠 Deactivating bin: $binId');
      print('🟠 API URL: $baseUrl/bins/deactivate');

      final response = await http.post(
        Uri.parse('$baseUrl/bins/deactivate'),
        headers: _headers,
        body: jsonEncode({
          'binId': binId,
          'userId': userId,
          'sessionId': sessionId,
        }),
      );

      print('🟠 Response Status: ${response.statusCode}');
      print('🟠 Response Body: ${response.body}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        throw Exception('Server returned empty response');
      }

      // Try to decode JSON
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (jsonError) {
        print('❌ JSON Parse Error: $jsonError');
        print('❌ Raw Response: ${response.body}');
        throw Exception('Invalid response from server: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');
      }

      if (response.statusCode == 200 && data['success'] == true) {
        // Send to ESP32-CAM via Bluetooth
        await _sendToESP32CAM('DEACTIVATE_BIN');
        
        return data;
      } else if (response.statusCode == 403) {
        throw Exception('Unauthorized to deactivate this bin');
      } else {
        throw Exception(data['error'] ?? 'Failed to deactivate bin');
      }
    } catch (e) {
      print('❌ Error in deactivateBin: $e');
      rethrow;
    }
  }

  /// Send commands to ESP32-CAM via Bluetooth
  Future<void> _sendToESP32CAM(String command) async {
    // TODO: Implement Bluetooth communication with ESP32-CAM
    // This will use flutter_blue_plus or similar package
    // await characteristic.write(utf8.encode(command + '\n'));
    print('Sending to ESP32-CAM: $command');
  }

  /// Get current user's auth token
  Future<String?> _getCurrentUserToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }
}
