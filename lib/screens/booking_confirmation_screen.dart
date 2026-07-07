import 'package:flutter/material.dart';
import '../services/database_service.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({
    super.key,
    required this.userId,
    required this.serviceName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.price,
    this.notes = '',
  });

  final int userId;
  final String serviceName;
  final String appointmentDate;
  final String appointmentTime;
  final String price;
  final String notes;

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool _isSubmitting = false;

  static const Color _primary = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Color(0xFFF8FAFC);

  Future<void> _confirmBooking() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final result = await DatabaseService.createAppointment(
      userId: widget.userId,
      title: widget.serviceName,
      appointmentDate: widget.appointmentDate,
      appointmentTime: widget.appointmentTime,
      notes: widget.notes,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final success = result['success'] == true;
    final message = success
        ? 'Booking Confirmed Successfully!'
        : (result['message']?.toString() ?? 'Failed to confirm booking.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? const Color(0xFF059669)
            : const Color(0xFFDC2626),
      ),
    );

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/appointments',
        (route) => route.settings.name == '/' || route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
        title: const Text(
          'Booking Confirmation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Review Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DetailRow(label: 'Service', value: widget.serviceName),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Date & Time',
                      value:
                          '${widget.appointmentDate} at ${widget.appointmentTime}',
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(label: 'Price', value: widget.price),
                    if (widget.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _DetailRow(label: 'Notes', value: widget.notes.trim()),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Payment will be made physically on arrival',
                        style: TextStyle(
                          fontSize: 13,
                          color: _muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _confirmBooking,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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
              color: _BookingConfirmationScreenState._muted,
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
              color: _BookingConfirmationScreenState._primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
