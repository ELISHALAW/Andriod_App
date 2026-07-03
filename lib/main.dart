import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/database_test_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blank App',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      initialRoute: '/', // Important
      routes: {
        '/': (context) => const HomeScreen(), // Important
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/database-test': (context) => const DatabaseTestScreen(),
        '/profile': (context) => const ProfileScreen(),
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
  String _userName = 'Alex';
  bool _isUserLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _checkLoggedIn();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('userName');
    if (savedName != null && savedName.isNotEmpty) {
      setState(() => _userName = savedName);
    }
  }

  Future<void> _checkLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    setState(() => _isUserLoggedIn = userId != null);
  }

  void _onNavTap(int idx) {
    if (idx == 3) {
      Navigator.pushNamed(context, '/profile');
    } else {
      setState(() => _selectedIndex = idx);
    }
  }

  Widget _buildMessagesBody() {
    final messages = [
      {
        'title': 'Project kickoff',
        'subtitle': 'Let’s meet at 10:00 to review requirements.',
        'time': 'Now',
        'unread': true,
      },
      {
        'title': 'Design review',
        'subtitle': 'The new wireframes are ready for your feedback.',
        'time': '1h ago',
        'unread': true,
      },
      {
        'title': 'Sales update',
        'subtitle': 'Monthly report has been uploaded to the dashboard.',
        'time': 'Yesterday',
        'unread': false,
      },
      {
        'title': 'Support team',
        'subtitle': 'We have scheduled a follow-up call tomorrow.',
        'time': '2d ago',
        'unread': false,
      },
      {
        'title': 'Anna Morris',
        'subtitle': 'I reviewed the latest draft and it looks great.',
        'time': '3d ago',
        'unread': false,
      },
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messages',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Catch up with your latest conversations.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Color(0xFF94A3B8)),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search messages',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  Icon(Icons.filter_list, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('All', true),
                  const SizedBox(width: 10),
                  _buildChip('Unread', false),
                  const SizedBox(width: 10),
                  _buildChip('Mentions', false),
                  const SizedBox(width: 10),
                  _buildChip('Archived', false),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Recent',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),
            ...messages.map((message) {
              return Column(
                children: [
                  _buildMessageCard(
                    title: message['title'] as String,
                    subtitle: message['subtitle'] as String,
                    time: message['time'] as String,
                    unread: message['unread'] as bool,
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Archive all'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('New message'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsBody() {
    return const Center(
      child: Text(
        'Alerts',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMessageCard({
    required String title,
    required String subtitle,
    required String time,
    required bool unread,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: unread
              ? const Color(0xFF0F172A)
              : const Color(0xFFE2E8F0),
          child: Icon(
            Icons.chat_bubble_outline,
            color: unread ? Colors.white : const Color(0xFF64748B),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: unread ? const Color(0xFF0F172A) : const Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            if (unread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'New',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildChip(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = const Color(0xFF0F172A);
    final muted = const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, $_userName',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Here’s what’s new for you',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined, color: Color(0xFF0F172A)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.storage, color: Color(0xFF0F172A)),
            tooltip: 'Test Database',
            onPressed: () => Navigator.pushNamed(context, '/database-test'),
          ),
          if (!_isUserLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: IconButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFe2e8f0),
                  child: const Icon(Icons.person, color: Color(0xFF0F172A)),
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Color(0xFF94A3B8)),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        Icon(Icons.filter_list, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Promo cards
                  SizedBox(
                    height: 150,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildPromoCard(
                          title: 'Start a project',
                          subtitle: 'Create something new today',
                          color: const Color(0xFF6366F1),
                          icon: Icons.lightbulb_outline,
                        ),
                        const SizedBox(width: 12),
                        _buildPromoCard(
                          title: 'Explore tutorials',
                          subtitle: 'Learn new skills',
                          color: const Color(0xFF06B6D4),
                          icon: Icons.school_outlined,
                        ),
                        const SizedBox(width: 12),
                        _buildPromoCard(
                          title: 'Team space',
                          subtitle: 'Collaborate with others',
                          color: const Color(0xFF10B981),
                          icon: Icons.group_outlined,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Categories
                  const Text(
                    'Categories',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.85,
                    children: [
                      _buildCategory(Icons.code, 'Dev'),
                      _buildCategory(Icons.design_services, 'Design'),
                      _buildCategory(Icons.analytics, 'Data'),
                      _buildCategory(Icons.business_center, 'Biz'),
                      _buildCategory(Icons.sports_esports, 'Games'),
                      _buildCategory(Icons.health_and_safety, 'Health'),
                      _buildCategory(Icons.public, 'Travel'),
                      _buildCategory(Icons.lightbulb, 'Ideas'),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Recommended
                  const Text(
                    'Recommended',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: List.generate(3, (i) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          title: Text(
                            'Recommended item ${i + 1}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Quick summary of this item.',
                            style: TextStyle(color: muted),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          _buildMessagesBody(),
          _buildAlertsBody(),
        ],
      ),
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
            icon: Icon(Icons.message_outlined),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.95), color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
        ),
      ],
    );
  }
}
