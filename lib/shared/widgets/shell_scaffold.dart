import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  static const _tabs = ['/home', '/files', '/devices', '/profile'];

  int _locationIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _tabs.indexWhere((t) => location.startsWith(t));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _locationIndex(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('echoSystem')),
      drawer: _buildDrawer(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [EchoColors.navySlate, EchoColors.deepNavy],
            stops: [0.0, 1.0],
          ),
        ),
        child: child,
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                EchoColors.navySlate.withOpacity(0.95),
                EchoColors.deepNavy.withOpacity(0.98),
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
            currentIndex: idx,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: EchoColors.warmGold,
            unselectedItemColor: EchoColors.pewter,
            type: BottomNavigationBarType.fixed,
            onTap: (i) => context.go(_tabs[i]),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: 'Files'),
              BottomNavigationBarItem(icon: Icon(Icons.devices_outlined), label: 'Devices'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EchoColors.navySlate.withOpacity(0.97),
              EchoColors.deepNavy.withOpacity(0.98),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [EchoColors.chromeBlueGrey, EchoColors.navySlate],
                ),
                border: Border(
                  bottom: BorderSide(color: EchoColors.warmGold.withOpacity(0.3), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EchoColors.warmGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.share, color: EchoColors.warmGold, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text('echoSystem', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
                  const Text('Local Share', style: TextStyle(color: EchoColors.warmGold, fontSize: 14)),
                ],
              ),
            ),
            _drawerItem(Icons.home, 'Home', () => context.go('/home')),
            _drawerItem(Icons.folder, 'Files', () => context.go('/files')),
            _drawerItem(Icons.devices, 'Devices', () => context.go('/devices')),
            _drawerItem(Icons.person, 'Profile', () => context.go('/profile')),
            const Divider(color: EchoColors.pewter, thickness: 0.5),
            _drawerItem(Icons.settings, 'Settings', () => context.go('/settings')),
            _drawerItem(Icons.history, 'Logs', () => context.go('/logs')),
            _drawerItem(Icons.palette, 'Themes', () => {}), // placeholder
            _drawerItem(Icons.exit_to_app, 'Exit', () => {}, // placeholder
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: EchoColors.warmGold),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      hoverColor: EchoColors.warmGold.withOpacity(0.1),
      splashColor: EchoColors.warmGold.withOpacity(0.2),
    );
  }
}
