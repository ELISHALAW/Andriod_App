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

  /// Create an appointment
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
      final success = data['success'] == true && response.statusCode == 200;
      return {
        'success': success,
        'message': data['message']?.toString() ?? 'Unknown response',
        'data': data['data'] ?? null,
      };
    } on FormatException {
      return {
        'success': false,
        'message': 'Cancel appointment failed: invalid server response.',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Cancel appointment failed: $e',
        'data': null,
      };
    }
  }

  /// Fetch messages for a user
  static Future<Map<String, dynamic>> getMessages({required int userId}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/get_messages.php'),
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
        'message': 'Fetch messages failed: $e',
        'data': [],
      };
    }
  }

  /// Create a message for a user
  static Future<Map<String, dynamic>> createMessage({
    required int userId,
    required String sender,
    required String subject,
    required String body,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/create_message.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'sender': sender,
              'subject': subject,
              'body': body,
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
        'message': 'Create message failed: $e',
        'data': null,
      };
    }
  }

  /// Convenience method for support chat from app user to admin.
  static Future<Map<String, dynamic>> sendToAdmin({
    required int userId,
    required String message,
    String subject = 'Support Request',
  }) async {
    return createMessage(
      userId: userId,
      sender: 'User',
      subject: subject,
      body: message,
    );
  }

  /// Mark a message as read
  static Future<Map<String, dynamic>> markMessageRead({
    required int messageId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/mark_message_read.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': messageId}),
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
        'message': 'Mark message failed: $e',
        'data': null,
      };
    }
  }

  /// Delete a message
  static Future<Map<String, dynamic>> deleteMessage({
    required int messageId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/delete_message.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': messageId}),
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
        'message': 'Delete message failed: $e',
        'data': null,
      };
    }
  }

  /// Fetch documents for a user
  static Future<Map<String, dynamic>> getDocuments({
    required int userId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/get_documents.php'),
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
        'message': 'Fetch documents failed: $e',
        'data': [],
      };
    }
  }

  /// Create a document record
  static Future<Map<String, dynamic>> createDocument({
    required int userId,
    required String title,
    required String documentType,
    required String fileName,
    required String notes,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/create_document.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'title': title,
              'document_type': documentType,
              'file_name': fileName,
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
        'message': 'Create document failed: $e',
        'data': null,
      };
    }
  }

  /// Delete a document record
  static Future<Map<String, dynamic>> deleteDocument({
    required int documentId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/delete_document.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': documentId}),
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
        'message': 'Delete document failed: $e',
        'data': null,
      };
    }
  }
}
