import 'package:flutter/material.dart';
import '../services/database_service.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String _statusMessage = '';

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing connection...';
    });

    final result = await DatabaseService.testConnection();

    setState(() {
      _result = result;
      _isLoading = false;
      _statusMessage = result['message'] ?? 'Test completed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Connection Test'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testConnection,
                icon: const Icon(Icons.storage),
                label: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result != null && _result!['success'] == true
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  border: Border.all(
                    color: _result != null && _result!['success'] == true
                        ? Colors.green
                        : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _result != null && _result!['success'] == true
                          ? Icons.check_circle
                          : Icons.error,
                      color: _result != null && _result!['success'] == true
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _result != null && _result!['success'] == true
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Result Details
            if (_result != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Connection Details:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              _buildResultCard(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFe2e8f0)),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFF8FAFC),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            'Status',
            result['success'] == true ? '✓ Success' : '✗ Failed',
          ),
          const Divider(),
          _buildDetailRow('Message', result['message'] ?? 'N/A'),
          if (result['data'] != null) ...[
            const Divider(),
            ..._buildDataRows(result['data']),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDataRows(dynamic data) {
    if (data is Map) {
      return data.entries
          .map((e) => _buildDetailRow(e.key.toString(), e.value.toString()))
          .toList();
    }
    return [];
  }
}
