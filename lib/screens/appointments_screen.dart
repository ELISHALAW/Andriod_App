import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _isLoading = false;
  bool _isCancelling = false;
  int? _userId;
  String _statusMessage = '';
  List<Map<String, dynamic>> _appointments = [];

  static const Color _primary = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      setState(() {
        _userId = null;
        _appointments = [];
        _statusMessage = 'Please login to manage appointments.';
      });
      return;
    }

    setState(() {
      _userId = userId;
      _isLoading = true;
      _statusMessage = 'Loading appointments...';
    });

    final result = await DatabaseService.getAppointments(userId: userId);
    final data = result['data'];

    setState(() {
      _isLoading = false;
      _statusMessage = result['message'] ?? '';
      _appointments = data is List
          ? data
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : [];
    });
  }

  Future<void> _goToBookingScreen() async {
    final result = await Navigator.pushNamed(context, '/calendar');
    if (!mounted) return;
    if (result != null) {
      await _loadAppointments();
    }
  }

  String _normalizedStatus(String status) {
    final value = status.trim().toLowerCase();
    if (value == 'cancelled') return 'cancelled';
    if (value == 'pending') return 'pending';
    return 'confirmed';
  }

  ({Color text, Color bg}) _statusColors(String status) {
    switch (_normalizedStatus(status)) {
      case 'cancelled':
        return (text: const Color(0xFFDC2626), bg: const Color(0xFFFEE2E2));
      case 'pending':
        return (text: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7));
      default:
        return (text: const Color(0xFF059669), bg: const Color(0xFFDCFCE7));
    }
  }

  String _statusLabel(String status) {
    switch (_normalizedStatus(status)) {
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
        return 'Pending';
      default:
        return 'Confirmed';
    }
  }

  bool _canCancel(String status) {
    final normalized = _normalizedStatus(status);
    return normalized == 'confirmed' || normalized == 'pending';
  }

  Future<void> _confirmAndCancelAppointment({
    required int appointmentId,
    required String status,
  }) async {
    if (!_canCancel(status) || _isCancelling) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isCancelling = true);

    final result = await DatabaseService.cancelAppointment(
      appointmentId: appointmentId,
    );

    if (!mounted) return;
    setState(() => _isCancelling = false);

    _showSnackBar(result['success'] == true, result['message'] ?? '');

    if (result['success'] == true) {
      await _loadAppointments();
    }
  }

  void _showSnackBar(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.isEmpty ? 'Request completed.' : message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  String _displayDateTime(String date, String time) {
    final cleanDate = date.trim();
    final cleanTime = time.trim();
    if (cleanDate.isEmpty && cleanTime.isEmpty) {
      return 'Date and time unavailable';
    }
    if (cleanDate.isEmpty) return cleanTime;
    if (cleanTime.isEmpty) return cleanDate;
    return '$cleanDate at $cleanTime';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadAppointments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToBookingScreen,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Book'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Upcoming bookings',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'View your bookings and cancel when needed.',
              style: TextStyle(fontSize: 14, color: _muted),
            ),
            const SizedBox(height: 18),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_userId == null)
              _buildEmptyState(Icons.lock_outline, _statusMessage)
            else if (_appointments.isEmpty)
              _buildEmptyState(
                Icons.event_available_outlined,
                'No appointments yet. Tap Book to add your first booking.',
              )
            else
              ..._appointments.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAppointmentCard(item),
                ),
              ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> item) {
    final id = int.tryParse(item['id'].toString()) ?? 0;
    final title = item['title']?.toString() ?? 'Appointment';
    final date = item['appointment_date']?.toString() ?? '';
    final time = item['appointment_time']?.toString() ?? '';
    final notes = item['notes']?.toString() ?? '';
    final status = item['status']?.toString() ?? 'confirmed';
    final normalizedStatus = _normalizedStatus(status);
    final canCancel = _canCancel(status);
    final statusPalette = _statusColors(status);
    final isCancelled = normalizedStatus == 'cancelled';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCancelled
              ? const Color(0xFFFCA5A5)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: isCancelled
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFEFF6FF),
              child: Icon(
                isCancelled
                    ? Icons.event_busy_outlined
                    : Icons.event_note_outlined,
                color: isCancelled
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _primary,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _displayDateTime(date, time),
                    style: const TextStyle(color: _muted),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(notes, style: const TextStyle(color: _muted)),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusPalette.bg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: statusPalette.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (canCancel)
              IconButton(
                tooltip: _isCancelling ? 'Cancelling...' : 'Cancel appointment',
                onPressed: _isCancelling
                    ? null
                    : () => _confirmAndCancelAppointment(
                        appointmentId: id,
                        status: status,
                      ),
                icon: const Icon(Icons.close),
                color: const Color(0xFFDC2626),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted),
          ),
          if (_userId != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _goToBookingScreen,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Book Appointment'),
            ),
          ],
        ],
      ),
    );
  }
}
