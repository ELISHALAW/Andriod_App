import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/appointment_detail_screen.dart';
import 'screens/appointments_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reset_password_screen.dart';
import 'services/database_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Client Booking App',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/appointments': (context) => const AppointmentsScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'Guest';
  bool _isUserLoggedIn = false;
  bool _isLoadingUpcoming = false;
  Map<String, dynamic>? _upcomingAppointment;

  String get _malaysiaGreeting {
    final malaysiaTime = DateTime.now().toUtc().add(const Duration(hours: 8));
    final hour = malaysiaTime.hour;

    if (hour >= 6 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('userName');
    final userId = prefs.getInt('userId');

    if (!mounted) return;
    setState(() {
      _isUserLoggedIn = userId != null;
      if (savedName != null && savedName.isNotEmpty) {
        _userName = savedName;
      }
    });

    await _loadUpcomingAppointment(forceUserId: userId);
  }

  String _normalizedStatus(String status) {
    final value = status.trim().toLowerCase();
    if (value == 'cancelled') return 'cancelled';
    if (value == 'pending') return 'pending';
    return 'confirmed';
  }

  DateTime? _parseAppointmentDateTime(Map<String, dynamic> item) {
    final rawDate = (item['appointment_date']?.toString() ?? '').trim();
    final rawTime = (item['appointment_time']?.toString() ?? '').trim();

    if (rawDate.isEmpty) {
      return null;
    }

    final timeValue = rawTime.isEmpty
        ? '00:00:00'
        : (rawTime.length == 5 ? '$rawTime:00' : rawTime);

    final parsed = DateTime.tryParse('$rawDate $timeValue');
    if (parsed != null) {
      return parsed;
    }

    if (!rawDate.contains('/')) {
      return null;
    }

    final dateParts = rawDate.split('/');
    if (dateParts.length != 3) {
      return null;
    }

    final first = int.tryParse(dateParts[0]);
    final second = int.tryParse(dateParts[1]);
    final third = int.tryParse(dateParts[2]);
    if (first == null || second == null || third == null) {
      return null;
    }

    final timeParts = timeValue.split(':');
    final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    final secondValue = timeParts.length > 2
        ? int.tryParse(timeParts[2]) ?? 0
        : 0;

    if (dateParts[0].length == 4) {
      return DateTime(first, second, third, hour, minute, secondValue);
    }

    return DateTime(third, second, first, hour, minute, secondValue);
  }

  Map<String, dynamic>? _findNextUpcomingAppointment(
    List<Map<String, dynamic>> appointments,
  ) {
    final now = DateTime.now();
    final upcoming = appointments.where((item) {
      final status = item['status']?.toString() ?? 'confirmed';
      final appointmentDateTime = _parseAppointmentDateTime(item);
      return _normalizedStatus(status) != 'cancelled' &&
          appointmentDateTime != null &&
          (appointmentDateTime.isAtSameMomentAs(now) ||
              appointmentDateTime.isAfter(now));
    }).toList();

    if (upcoming.isEmpty) {
      return null;
    }

    upcoming.sort((a, b) {
      final aDate = _parseAppointmentDateTime(a) ?? DateTime(2999);
      final bDate = _parseAppointmentDateTime(b) ?? DateTime(2999);
      return aDate.compareTo(bDate);
    });

    return upcoming.first;
  }

  Future<void> _loadUpcomingAppointment({int? forceUserId}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = forceUserId ?? prefs.getInt('userId');

    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _isLoadingUpcoming = false;
        _upcomingAppointment = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoadingUpcoming = true;
    });

    final result = await DatabaseService.getAppointments(userId: userId);
    final data = result['data'];

    final appointments = data is List
        ? data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    final nextUpcoming = _findNextUpcomingAppointment(appointments);

    if (!mounted) return;
    setState(() {
      _isLoadingUpcoming = false;
      _upcomingAppointment = nextUpcoming;
    });
  }

  Future<void> _openUpcomingAppointmentDetail() async {
    if (_upcomingAppointment == null) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AppointmentDetailScreen(appointment: _upcomingAppointment!),
      ),
    );

    if (!mounted) return;
    if (updated == true) {
      await _loadUpcomingAppointment();
    }
  }

  void _onNavTap(int idx) {
    setState(() => _selectedIndex = idx);
    if (idx == 0) {
      _loadUpcomingAppointment();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(
        isUserLoggedIn: _isUserLoggedIn,
        userName: _userName,
        isLoadingUpcoming: _isLoadingUpcoming,
        upcomingAppointment: _upcomingAppointment,
        onRefreshUpcoming: _loadUpcomingAppointment,
        onViewUpcomingDetails: _openUpcomingAppointmentDetail,
        onGoToBook: () => _onNavTap(1),
        onGoToAppointments: () => _onNavTap(2),
        onGoToProfile: () => _onNavTap(3),
      ),
      const CalendarScreen(),
      const AppointmentsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isUserLoggedIn
                        ? '$_malaysiaGreeting, $_userName'
                        : 'Welcome to Client Booking App',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isUserLoggedIn
                        ? 'Manage your bookings and appointments'
                        : 'Sign in to book appointments',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              actions: [
                if (!_isUserLoggedIn)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: IconButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      icon: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFE2E8F0),
                        child: Icon(Icons.person, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ),
              ],
            )
          : null,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0F172A),
        unselectedItemColor: const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Book Appointment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'My Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.isUserLoggedIn,
    required this.userName,
    required this.isLoadingUpcoming,
    required this.upcomingAppointment,
    required this.onRefreshUpcoming,
    required this.onViewUpcomingDetails,
    required this.onGoToBook,
    required this.onGoToAppointments,
    required this.onGoToProfile,
  });

  final bool isUserLoggedIn;
  final String userName;
  final bool isLoadingUpcoming;
  final Map<String, dynamic>? upcomingAppointment;
  final Future<void> Function() onRefreshUpcoming;
  final VoidCallback onViewUpcomingDetails;
  final VoidCallback onGoToBook;
  final VoidCallback onGoToAppointments;
  final VoidCallback onGoToProfile;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Removed Search Bar
            const SizedBox(height: 8),

            _UpcomingAppointmentCard(
              isLoggedIn: isUserLoggedIn,
              isLoading: isLoadingUpcoming,
              appointment: upcomingAppointment,
              onBookNow: onGoToBook,
              onViewDetails: onViewUpcomingDetails,
              onRefresh: onRefreshUpcoming,
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    title: 'Book Appointment',
                    subtitle: 'Reserve your slot',
                    icon: Icons.calendar_month_outlined,
                    color: const Color(0xFF2563EB),
                    onTap: onGoToBook,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    title: 'My Appointments',
                    subtitle: 'Track your bookings',
                    icon: Icons.event_note_outlined,
                    color: const Color(0xFF7C3AED),
                    onTap: onGoToAppointments,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    title: 'Profile',
                    subtitle: 'Manage your account',
                    icon: Icons.person_outline,
                    color: const Color(0xFF059669),
                    onTap: onGoToProfile,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            const Text(
              'Quick Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            const _OverviewTile(
              icon: Icons.check_circle_outline,
              title: 'Appointments this week',
              value: '3',
              color: Color(0xFF2563EB),
            ),
            const SizedBox(height: 10),
            const _OverviewTile(
              icon: Icons.schedule_outlined,
              title: 'Upcoming today',
              value: '1',
              color: Color(0xFF7C3AED),
            ),
            const SizedBox(height: 10),
            _OverviewTile(
              icon: Icons.person_outline,
              title: isUserLoggedIn
                  ? 'Signed in as $userName'
                  : 'Account status',
              value: isUserLoggedIn ? 'Active' : 'Guest',
              color: const Color(0xFF059669),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.78)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingAppointmentCard extends StatelessWidget {
  const _UpcomingAppointmentCard({
    required this.isLoggedIn,
    required this.isLoading,
    required this.appointment,
    required this.onBookNow,
    required this.onViewDetails,
    required this.onRefresh,
  });

  final bool isLoggedIn;
  final bool isLoading;
  final Map<String, dynamic>? appointment;
  final VoidCallback onBookNow;
  final VoidCallback onViewDetails;
  final Future<void> Function() onRefresh;

  String _statusLabel(String status) {
    final value = status.trim().toLowerCase();
    if (value == 'cancelled') return 'Cancelled';
    if (value == 'pending') return 'Pending';
    return 'Confirmed';
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
    final service = appointment?['title']?.toString() ?? 'Appointment';
    final date = appointment?['appointment_date']?.toString() ?? '';
    final time = appointment?['appointment_time']?.toString() ?? '';
    final status = appointment?['status']?.toString() ?? 'confirmed';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upcoming_outlined, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Upcoming Appointment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              IconButton(
                onPressed: isLoading ? null : onRefresh,
                tooltip: 'Refresh upcoming appointment',
                icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
              ),
            ],
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!isLoggedIn || appointment == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                const Text(
                  'No upcoming appointments',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onBookNow,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Book Now'),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  service,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _displayDateTime(date, time),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Status: ${_statusLabel(status)}',
                    style: const TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onViewDetails,
                  child: const Text('View Details'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
