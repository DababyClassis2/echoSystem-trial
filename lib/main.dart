import 'package:flutter/material.dart';

void main() {
  runApp(const EchoSystemApp());
}

class EchoSystemApp extends StatelessWidget {
  const EchoSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'echoSystem',
      theme: _buildPremiumTheme(),
      home: const EchoHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildPremiumTheme() {
    // Custom colors derived from the icon
    const Color chromeBlueGrey = Color(0xFF4A5B6E);
    const Color navySlate = Color(0xFF2C3E50);
    const Color pewter = Color(0xFF6B7B8D);
    const Color icyWhite = Color(0xFFF5F7FA);
    const Color warmGold = Color(0xFFD4C4A8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: chromeBlueGrey,
        secondary: warmGold,
        surface: navySlate,
        background: navySlate,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: navySlate,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: icyWhite,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: icyWhite),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: warmGold,
        unselectedItemColor: pewter,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: icyWhite, fontSize: 16),
        bodyMedium: TextStyle(color: pewter, fontSize: 14),
        titleLarge: TextStyle(color: icyWhite, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class EchoHomePage extends StatefulWidget {
  const EchoHomePage({super.key});

  @override
  State<EchoHomePage> createState() => _EchoHomePageState();
}

class _EchoHomePageState extends State<EchoHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    GlassmorphicCard(
      title: 'Home',
      content:
          'Welcome to echoSystem – your premium local sharing hub.\n\n'
          'Seamlessly share files, messages, and media with nearby devices. '
          'Fast, secure, and beautifully crafted.',
    ),
    GlassmorphicCard(
      title: 'Files',
      content:
          'Manage all your shared files.\n\n'
          'Browse, organise, and access documents, photos, and videos '
          'transferred through echoSystem. Everything at your fingertips.',
    ),
    GlassmorphicCard(
      title: 'Devices',
      content:
          'Discover connected devices.\n\n'
          'See who is on your local network, manage trusted connections, '
          'and monitor sharing activity in real time.',
    ),
    GlassmorphicCard(
      title: 'Profile',
      content:
          'Your profile and preferences.\n\n'
          'Customise your display name, avatar, theme preferences, and '
          'manage privacy settings for local sharing.',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('echoSystem'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2C3E50).withOpacity(0.9),
                const Color(0xFF1A252F).withOpacity(0.95),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFD4C4A8).withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
        ),
      ),
      drawer: _buildPremiumDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              const Color(0xFF2C3E50),
              const Color(0xFF1A252F),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF2C3E50).withOpacity(0.95),
                const Color(0xFF1A252F).withOpacity(0.98),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: 'Files'),
              BottomNavigationBarItem(icon: Icon(Icons.devices_outlined), label: 'Devices'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFFD4C4A8),
            unselectedItemColor: const Color(0xFF6B7B8D),
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C3E50).withOpacity(0.97),
              const Color(0xFF1A252F).withOpacity(0.98),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4A5B6E),
                    const Color(0xFF2C3E50),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFD4C4A8).withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4C4A8).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Color(0xFFD4C4A8),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'echoSystem',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Text(
                    'Local Share',
                    style: TextStyle(
                      color: Color(0xFFD4C4A8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.system_update, 'Update', () {}),
            _buildDrawerItem(Icons.settings, 'Settings', () {}),
            _buildDrawerItem(Icons.history, 'Logs', () {}),
            _buildDrawerItem(Icons.palette, 'Themes', () {}),
            const Divider(color: Color(0xFF6B7B8D), thickness: 0.5),
            _buildDrawerItem(Icons.exit_to_app, 'Exit', () {
              // Optionally show a dialog or exit
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFD4C4A8)),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
      hoverColor: const Color(0xFFD4C4A8).withOpacity(0.1),
      splashColor: const Color(0xFFD4C4A8).withOpacity(0.2),
    );
  }
}

// A glass‑like card widget for the main content areas
class GlassmorphicCard extends StatelessWidget {
  final String title;
  final String content;

  const GlassmorphicCard({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: const Color(0xFFD4C4A8).withOpacity(0.2),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF5F7FA),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7B8D),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}