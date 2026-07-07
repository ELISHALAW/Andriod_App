import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  int? _userId;
  bool _isLoading = false;
  bool _isSaving = false;
  List<Map<String, dynamic>> _allAppointments = [];
  Map<DateTime, List<Map<String, dynamic>>> _eventMap = {};

  static const Color _primary = Color(0xFF0F172A);
  static const Color _accent = Color(0xFF6366F1);
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
        _allAppointments = [];
      });
      return;
    }

    setState(() {
      _userId = userId;
      _isLoading = true;
    });

    final result = await DatabaseService.getAppointments(userId: userId);
    final data = result['data'];

    final List<Map<String, dynamic>> appointments = data is List
        ? data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : [];

    final Map<DateTime, List<Map<String, dynamic>>> eventMap = {};
    for (final appt in appointments) {
      final dateStr = appt['appointment_date'] as String?;
      if (dateStr == null || dateStr.isEmpty) continue;
      try {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final key = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          eventMap.putIfAbsent(key, () => []).add(appt);
        }
      } catch (_) {}
    }

    setState(() {
      _isLoading = false;
      _allAppointments = appointments;
      _eventMap = eventMap;
    });
  }

  List<Map<String, dynamic>> _eventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _eventMap[key] ?? [];
  }

  List<Map<String, dynamic>> get _selectedDayAppointments =>
      _eventsForDay(_selectedDay);

  String _formatDateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dow = days[date.weekday - 1];
    return '$dow, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _displayTime(String? t) {
    if (t == null || t.isEmpty) return '';
    try {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = parts[1];
      return '${h > 12 ? h - 12 : (h == 0 ? 12 : h)}:$m ${h >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return t;
    }
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF059669);
      case 'cancelled':
        return const Color(0xFFDC2626);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return _muted;
    }
  }

  String _timeKeyFromTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _normalizeApiTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = parts[0].padLeft(2, '0');
    final minute = parts[1].padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _isPastDateTime(DateTime date, TimeOfDay time) {
    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return selected.isBefore(DateTime.now());
  }

  bool _isActiveBookingStatus(String? status) {
    final value = (status ?? '').toLowerCase();
    return value != 'cancelled';
  }

  bool _isTimeSlotAlreadyBooked(DateTime date, TimeOfDay time) {
    final dateKey = _formatDateKey(date);
    final timeKey = _timeKeyFromTimeOfDay(time);

    return _allAppointments.any((appt) {
      final status = appt['status']?.toString();
      if (!_isActiveBookingStatus(status)) {
        return false;
      }

      final apptDate = appt['appointment_date']?.toString() ?? '';
      final apptTime = _normalizeApiTime(
        appt['appointment_time']?.toString() ?? '',
      );

      return apptDate == dateKey && apptTime == timeKey;
    });
  }

  String? _validateBookingSelection({
    required String serviceName,
    required DateTime date,
    required TimeOfDay time,
  }) {
    if (serviceName.trim().isEmpty) {
      return 'Please enter service name.';
    }

    if (_isPastDateTime(date, time)) {
      return 'You cannot book in the past.';
    }

    if (_isTimeSlotAlreadyBooked(date, time)) {
      return 'Time slot already booked.';
    }

    return null;
  }

  Future<void> _openBookDialog() async {
    final userId = _userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to book an appointment.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final titleCtrl = TextEditingController(text: 'Consultation');
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? validationError;
    DateTime pickedDate = _selectedDay.isBefore(DateTime.now())
        ? DateTime.now().add(const Duration(days: 1))
        : _selectedDay;
    TimeOfDay pickedTime = const TimeOfDay(hour: 10, minute: 0);

    validationError = _validateBookingSelection(
      serviceName: titleCtrl.text,
      date: pickedDate,
      time: pickedTime,
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final canSubmit =
              !_isSaving &&
              (validationError == null) &&
              titleCtrl.text.trim().isNotEmpty;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.event_available, color: _accent),
                SizedBox(width: 8),
                Text(
                  'Book Appointment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      onChanged: (_) {
                        setS(() {
                          validationError = _validateBookingSelection(
                            serviceName: titleCtrl.text,
                            date: pickedDate,
                            time: pickedTime,
                          );
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Title',
                        prefixIcon: const Icon(
                          Icons.title,
                          color: _accent,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: pickedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (d != null) {
                          setS(() {
                            pickedDate = d;
                            validationError = _validateBookingSelection(
                              serviceName: titleCtrl.text,
                              date: pickedDate,
                              time: pickedTime,
                            );
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: _accent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date',
                                  style: TextStyle(fontSize: 11, color: _muted),
                                ),
                                Text(
                                  _displayDate(pickedDate),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: pickedTime,
                        );
                        if (t != null) {
                          setS(() {
                            pickedTime = t;
                            validationError = _validateBookingSelection(
                              serviceName: titleCtrl.text,
                              date: pickedDate,
                              time: pickedTime,
                            );
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: _accent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Time',
                                  style: TextStyle(fontSize: 11, color: _muted),
                                ),
                                Text(
                                  _displayTime(
                                    '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (validationError != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 16,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              validationError!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: !canSubmit
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        final error = _validateBookingSelection(
                          serviceName: titleCtrl.text,
                          date: pickedDate,
                          time: pickedTime,
                        );
                        if (error != null) {
                          setS(() => validationError = error);
                          return;
                        }

                        setS(() => _isSaving = true);
                        final result = await DatabaseService.createAppointment(
                          userId: userId,
                          title: titleCtrl.text.trim(),
                          appointmentDate: _formatDateKey(pickedDate),
                          appointmentTime:
                              '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}',
                          notes: notesCtrl.text.trim(),
                        );
                        setS(() => _isSaving = false);
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? ''),
                              backgroundColor: result['success'] == true
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626),
                            ),
                          );
                          if (result['success'] == true) {
                            await _loadAppointments();
                          }
                        }
                      },
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Book'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedDayAppointments;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'My Calendar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _primary),
            onPressed: _loadAppointments,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : Column(
              children: [
                // ── Calendar ──────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                    eventLoader: _eventsForDay,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    onDaySelected: (selected, focused) => setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    }),
                    onPageChanged: (focused) =>
                        setState(() => _focusedDay = focused),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: _primary,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: _primary,
                      ),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                      weekendStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      todayDecoration: BoxDecoration(
                        color: _accent.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      todayTextStyle: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                      ),
                      defaultDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      weekendDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      outsideDaysVisible: false,
                      markerDecoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      markersMaxCount: 3,
                      markerSize: 6,
                      markerMargin: const EdgeInsets.only(top: 1),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Section title ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayDate(_selectedDay),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                              ),
                            ),
                            Text(
                              selected.isEmpty
                                  ? 'No appointments'
                                  : '${selected.length} appointment${selected.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_userId == null)
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.lock_outline, size: 14),
                          label: const Text('Sign in'),
                          style: TextButton.styleFrom(
                            foregroundColor: _accent,
                            iconColor: _accent,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Appointments list ─────────────────────────────────────
                Expanded(
                  child: selected.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 52,
                                color: _muted.withOpacity(0.4),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No appointments on this day',
                                style: TextStyle(color: _muted, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap + to book one',
                                style: TextStyle(color: _muted, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                          itemCount: selected.length,
                          itemBuilder: (ctx, i) {
                            final a = selected[i];
                            final title = (a['title'] ?? 'No title') as String;
                            final time =
                                (a['appointment_time'] ?? '') as String;
                            final notes = (a['notes'] ?? '') as String;
                            final status = (a['status'] ?? 'pending') as String;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.event,
                                      color: _accent,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: _primary,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _statusColor(
                                                  status,
                                                ).withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: _statusColor(status),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (time.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 12,
                                                color: _muted,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _displayTime(time),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: _muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (notes.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            notes,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _muted,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBookDialog,
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Book',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
