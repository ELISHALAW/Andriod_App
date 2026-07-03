import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/database_test_screen.dart';

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

  void _onNavTap(int idx) {
    setState(() => _selectedIndex = idx);
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
          children: const [
            Text(
              'Good morning, Alex',
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
      body: SafeArea(
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
