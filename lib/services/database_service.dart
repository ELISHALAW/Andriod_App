import 'package:http/http.dart' as http;
import 'dart:convert';

class DatabaseService {
  // Update this URL to match your PHP backend location.
  // If you run `php -S localhost:8000` from backend/api, the endpoint is:
  // http://localhost:8000/test_connection.php
  static const String baseUrl = 'http://localhost:8000';

  /// Test MySQL connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/test_connection.php'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Unknown response',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection failed: $e',
        'data': null,
      };
    }
  }

  /// Register a user in the backend
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'phone_number': phone,
              'address': address,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201
            ? (data['success'] ?? false)
            : false,
        'message': data['message'] ?? 'Unknown response',
        'errors': data['errors'] ?? null,
        'data': data['data'] ?? null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: $e',
        'errors': null,
        'data': null,
      };
    }
  }

  /// Login a user in the backend
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200
            ? (data['success'] ?? false)
            : false,
        'message': data['message'] ?? 'Unknown response',
        'data': data['data'] ?? null,
      };
    } catch (e) {
      return {'success': false, 'message': 'Login failed: $e', 'data': null};
    }
  }
}
