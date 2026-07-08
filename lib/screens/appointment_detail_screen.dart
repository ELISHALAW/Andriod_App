import 'package:flutter/material.dart';

import '../services/database_service.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({super.key, required this.appointment});

  final Map<String, dynamic> appointment;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  bool _isCancelling = false;

  static const Color _primary = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Color(0xFFF8FAFC);

  int get _id => int.tryParse(widget.appointment['id'].toString()) ?? 0;
  String get _title => widget.appointment['title']?.toString() ?? 'Appointment';
  String get _date => widget.appointment['appointment_date']?.toString() ?? '';
  String get _time => widget.appointment['appointment_time']?.toString() ?? '';
  String get _notes => widget.appointment['notes']?.toString() ?? '';
  String get _status => widget.appointment['status']?.toString() ?? 'confirmed';
  String get _clientName => widget.appointment['client_name']?.toString() ?? '';
  String get _clientEmail =>
      widget.appointment['client_email']?.toString() ?? '';
  String get _clientPhone =>
      widget.appointment['client_phone']?.toString() ?? '';
  String get _clientAge => widget.appointment['client_age']?.toString() ?? '';
  String get _clientGender =>
      widget.appointment['client_gender']?.toString() ?? '';

  String _normalizedStatus(String status) {
    final value = status.trim().toLowerCase();
    if (value == 'cancelled' || value == 'canceled') return 'cancelled';
    if (value == 'pending') return 'pending';
    return 'confirmed';
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

  bool get _canCancel {
    final normalized = _normalizedStatus(_status);
    return normalized == 'confirmed' || normalized == 'pending';
  }

  String get _displayDateTime {
    final cleanDate = _date.trim();
    final cleanTime = _time.trim();
    if (cleanDate.isEmpty && cleanTime.isEmpty) {
      return 'Date and time unavailable';
    }
    if (cleanDate.isEmpty) return cleanTime;
    if (cleanTime.isEmpty) return cleanDate;
    return '$cleanDate at $cleanTime';
  }

  String _displayValue(String value) {
    final clean = value.trim();
    return clean.isEmpty ? 'Not provided' : clean;
  }

  Future<void> _cancelAppointment() async {
    if (!_canCancel || _isCancelling || _id <= 0) return;

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

    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    final result = await DatabaseService.cancelAppointment(appointmentId: _id);

    if (!mounted) return;
    setState(() => _isCancelling = false);

    final success = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? 'Request completed.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusPalette = _statusColors(_status);

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.event_note_outlined,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _displayDateTime,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const SizedBox(
                          width: 90,
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _muted,
                            ),
                          ),
                        ),
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
                            _statusLabel(_status),
                            style: TextStyle(
                              color: statusPalette.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Notes', value: _notes),
                    ],
                    if (_id > 0) ...[
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Booking ID', value: '#$_id'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Client Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DetailRow(
                      label: 'Name',
                      value: _displayValue(_clientName),
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Email',
                      value: _displayValue(_clientEmail),
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Phone',
                      value: _displayValue(_clientPhone),
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(label: 'Age', value: _displayValue(_clientAge)),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Gender',
                      value: _displayValue(_clientGender),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_canCancel)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isCancelling ? null : _cancelAppointment,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _isCancelling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.close),
                    label: const Text(
                      'Cancel Booking',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'This appointment cannot be cancelled.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
