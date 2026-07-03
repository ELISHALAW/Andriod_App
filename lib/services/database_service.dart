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

  /// Fetch a user profile from the backend
  static Future<Map<String, dynamic>> getProfile({required int userId}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/get_profile.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': userId}),
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
      return {
        'success': false,
        'message': 'Fetch profile failed: $e',
        'data': null,
      };
    }
  }

  /// Update a user profile in the backend
  static Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String name,
    required String email,
    required String phone,
    required String address,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/update_profile.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': userId,
              'name': name,
              'email': email,
              'phone_number': phone,
              'address': address,
            }),
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
      return {
        'success': false,
        'message': 'Update profile failed: $e',
        'data': null,
      };
    }
  }

  /// Delete a user profile from the backend
  static Future<Map<String, dynamic>> deleteProfile({
    required int userId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/delete_profile.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': userId}),
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
      return {
        'success': false,
        'message': 'Delete profile failed: $e',
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

  /// Fetch notifications for a user
  static Future<Map<String, dynamic>> getNotifications({
    required int userId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/get_notifications.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200
            ? (data['success'] ?? false)
            : false,
        'message': data['message'] ?? 'Unknown response',
        'data': data['data'] ?? [],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Fetch notifications failed: $e',
        'data': [],
      };
    }
  }

  /// Mark a notification as read
  static Future<Map<String, dynamic>> markNotificationRead({
    required int notificationId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/mark_notification_read.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': notificationId}),
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
      return {
        'success': false,
        'message': 'Mark notification failed: $e',
        'data': null,
      };
    }
  }

  /// Delete a notification
  static Future<Map<String, dynamic>> deleteNotification({
    required int notificationId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/delete_notification.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': notificationId}),
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
      return {
        'success': false,
        'message': 'Delete notification failed: $e',
        'data': null,
      };
    }
  }

  /// Generate and save a random notification for a user
  static Future<Map<String, dynamic>> generateRandomNotification({
    required int userId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/create_random_notification.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201
            ? (data['success'] ?? false)
            : false,
        'message': data['message'] ?? 'Unknown response',
        'data': data['data'] ?? null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Generate notification failed: $e',
        'data': null,
      };
    }
  }

  /// Fetch appointments for a user
  static Future<Map<String, dynamic>> getAppointments({
    required int userId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/get_appointments.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200
            ? (data['success'] ?? false)
            : false,
        'message': data['message'] ?? 'Unknown response',
        'data': data['data'] ?? [],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Fetch appointments failed: $e',
        'data': [],
      };
    }
  }

  /// Create an appointment and matching notification
  static Future<Map<String, dynamic>> createAppointment({
    required int userId,
    required String title,
    required String appointmentDate,
    required String appointmentTime,
    required String notes,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/create_appointment.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'title': title,
              'appointment_date': appointmentDate,
              'appointment_time': appointmentTime,
              'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 || response.statusCode == 201
            ? (data['success'] ?? false)
            : false,
        'message': data['message'] ?? 'Unknown response',
        'data': data['data'] ?? null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Create appointment failed: $e',
        'data': null,
      };
    }
  }

  /// Cancel an appointment
  static Future<Map<String, dynamic>> cancelAppointment({
    required int appointmentId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/cancel_appointment.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': appointmentId}),
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
      return {
        'success': false,
        'message': 'Cancel appointment failed: $e',
        'data': null,
      };
    }
  }
}
