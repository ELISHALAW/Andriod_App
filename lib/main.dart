import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/appointments_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';

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

    setState(() {
      _isUserLoggedIn = userId != null;
      if (savedName != null && savedName.isNotEmpty) {
        _userName = savedName;
      }
    });
  }

  void _onNavTap(int idx) {
    setState(() => _selectedIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(
        isUserLoggedIn: _isUserLoggedIn,
        userName: _userName,
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
    required this.onGoToBook,
    required this.onGoToAppointments,
    required this.onGoToProfile,
  });

  final bool isUserLoggedIn;
  final String userName;
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Color(0xFF94A3B8)),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search appointments',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  Icon(Icons.tune, color: Color(0xFF94A3B8)),
                ],
              ),
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
