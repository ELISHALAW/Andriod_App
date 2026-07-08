import 'package:flutter/material.dart';

import '../services/database_service.dart';

class EditAppointmentScreen extends StatefulWidget {
  const EditAppointmentScreen({super.key, required this.appointment});

  final Map<String, dynamic> appointment;

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _dateCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _ageCtrl;

  final List<String> _genders = const [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _selectedGender;
  bool _isSaving = false;

  static const Color _primary = Color(0xFF0F172A);
  static const Color _accent = Color(0xFF4F46E5);
  static const Color _muted = Color(0xFF64748B);

  int get _appointmentId =>
      int.tryParse(widget.appointment['id'].toString()) ?? 0;
  int get _userId =>
      int.tryParse(widget.appointment['user_id'].toString()) ?? 0;
  String get _title {
    final value = widget.appointment['title']?.toString().trim() ?? '';
    return value.isEmpty ? 'Consultation' : value;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate =
        _parseDate(widget.appointment['appointment_date']?.toString()) ??
        DateTime.now();
    _selectedTime =
        _parseTime(widget.appointment['appointment_time']?.toString()) ??
        const TimeOfDay(hour: 10, minute: 0);

    _dateCtrl = TextEditingController(text: _dateKey(_selectedDate));
    _timeCtrl = TextEditingController(text: _timeKey(_selectedTime));
    _notesCtrl = TextEditingController(
      text: widget.appointment['notes']?.toString() ?? '',
    );
    _fullNameCtrl = TextEditingController(
      text: widget.appointment['client_name']?.toString() ?? '',
    );
    _emailCtrl = TextEditingController(
      text: widget.appointment['client_email']?.toString() ?? '',
    );
    _phoneCtrl = TextEditingController(
      text: widget.appointment['client_phone']?.toString() ?? '',
    );
    _ageCtrl = TextEditingController(
      text: widget.appointment['client_age']?.toString() ?? '',
    );

    final gender = widget.appointment['client_gender']?.toString().trim();
    if (gender != null && gender.isNotEmpty && _genders.contains(gender)) {
      _selectedGender = gender;
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _notesCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;

    if (!value.contains('/')) return null;
    final parts = value.split('/');
    if (parts.length != 3) return null;

    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    final third = int.tryParse(parts[2]);
    if (first == null || second == null || third == null) return null;

    if (parts[0].length == 4) return DateTime(first, second, third);
    return DateTime(third, second, first);
  }

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();

    final amPmMatch = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$',
    ).firstMatch(value);
    if (amPmMatch != null) {
      var hour = int.tryParse(amPmMatch.group(1) ?? '0') ?? 0;
      final minute = int.tryParse(amPmMatch.group(2) ?? '0') ?? 0;
      final period = (amPmMatch.group(3) ?? '').toLowerCase();
      if (period == 'pm' && hour < 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    }

    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _dateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  String _timeKey(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      _dateCtrl.text = _dateKey(picked);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked == null || !mounted) return;
    setState(() {
      _selectedTime = picked;
      _timeCtrl.text = _timeKey(picked);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_appointmentId <= 0 || _userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment context is invalid.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final result = await DatabaseService.updateAppointment(
      id: _appointmentId,
      userId: _userId,
      title: _title,
      appointmentDate: _dateCtrl.text.trim(),
      appointmentTime: _timeCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      clientName: _fullNameCtrl.text.trim(),
      clientEmail: _emailCtrl.text.trim(),
      clientPhone: _phoneCtrl.text.trim(),
      clientAge: _ageCtrl.text.trim(),
      clientGender: _selectedGender ?? '',
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    final success = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? 'Request completed.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (!success) return;

    final updated = result['data'];
    Navigator.pop(
      context,
      updated is Map ? Map<String, dynamic>.from(updated) : null,
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 20, color: _accent),
      suffixIcon: const Icon(Icons.edit_outlined, size: 18, color: _muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD6DBEA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
      fillColor: const Color(0xFFFBFCFF),
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Appointment'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F7FF), Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionCard(
                  title: 'Service Date & Time',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: _inputDecoration(
                          label: 'Date',
                          prefixIcon: Icons.calendar_today_outlined,
                        ),
                        validator: (value) => _validateRequired(value, 'Date'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _timeCtrl,
                        readOnly: true,
                        onTap: _pickTime,
                        decoration: _inputDecoration(
                          label: 'Time',
                          prefixIcon: Icons.access_time_outlined,
                        ),
                        validator: (value) => _validateRequired(value, 'Time'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  title: 'Notes',
                  child: TextFormField(
                    controller: _notesCtrl,
                    minLines: 3,
                    maxLines: 5,
                    decoration: _inputDecoration(label: 'Notes'),
                  ),
                ),
                const SizedBox(height: 14),
                _sectionCard(
                  title: 'Client Information',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameCtrl,
                        decoration: _inputDecoration(
                          label: 'Full Name',
                          prefixIcon: Icons.person_outline,
                        ),
                        validator: (value) =>
                            _validateRequired(value, 'Full Name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          label: 'Email',
                          prefixIcon: Icons.email_outlined,
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          label: 'Phone Number',
                          prefixIcon: Icons.call_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          label: 'Age',
                          prefixIcon: Icons.numbers_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: _inputDecoration(
                          label: 'Gender',
                          prefixIcon: Icons.person_pin_outlined,
                        ),
                        items: _genders
                            .map(
                              (gender) => DropdownMenuItem<String>(
                                value: gender,
                                child: Text(gender),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedGender = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
