import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/providers/providers.dart';

class ShellScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  final PageController _pageController = PageController();
  static const _tabs = ['/home', '/files', '/devices', '/profile'];
  DateTime? _lastBackPress;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If not on the home tab, go to home tab first
        final location = GoRouterState.of(context).uri.toString();
        if (location != '/home') {
          _pageController.jumpToPage(0);
          context.go('/home');
          return;
        }

        // On home tab — double-back to exit
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // Second press within 2 seconds — exit
        SystemNavigator.pop();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('echoSystem'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        drawer: _buildDrawer(context, ref),
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (i) => context.go(_tabs[i]),
          children: [widget.child],
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  EchoColors.navySlate.withValues(alpha: 0.95),
                  EchoColors.deepNavy.withValues(alpha: 0.98),
                ],
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _locationIndex(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: EchoColors.warmGold,
              unselectedItemColor: EchoColors.pewter,
              type: BottomNavigationBarType.fixed,
              onTap: (i) {
                _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                context.go(_tabs[i]);
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: 'Files'),
                BottomNavigationBarItem(icon: Icon(Icons.devices_outlined), label: 'Devices'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _locationIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _tabs.indexWhere((t) => location.startsWith(t));
    return idx < 0 ? 0 : idx;
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final avatarColor = Color(profileState.avatarColor);
    
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              EchoColors.navySlate.withValues(alpha: 0.97),
              EchoColors.deepNavy.withValues(alpha: 0.98),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          avatarColor.withValues(alpha: 0.8),
                          avatarColor.withValues(alpha: 0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    currentAccountPicture: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile');
                      },
                      child: CircleAvatar(
                        backgroundColor: avatarColor,
                        child: Text(
                          profileState.deviceName.isNotEmpty
                            ? profileState.deviceName[0].toUpperCase()
                            : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    accountName: Text(
                      profileState.deviceName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    accountEmail: const Text('Tap avatar to edit profile', style: TextStyle(color: EchoColors.pewter)),
                    onDetailsPressed: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    },
                  ),
                  _drawerItem(Icons.home_outlined, 'Home', () {
                    Navigator.pop(context);
                    context.go('/home');
                  }),
                  _drawerItem(Icons.folder_outlined, 'Files', () {
                    Navigator.pop(context);
                    context.go('/files');
                  }),
                  _drawerItem(Icons.devices_outlined, 'Devices', () {
                    Navigator.pop(context);
                    context.go('/devices');
                  }),
                  _drawerItem(Icons.person_outline, 'Profile', () {
                    Navigator.pop(context);
                    context.go('/profile');
                  }),
                  Consumer(
                    builder: (context, ref, _) {
                      final pending = ref.watch(activeTransfersProvider).length;
                      return ListTile(
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.swap_horiz_rounded, color: EchoColors.warmGold),
                            if (pending > 0)
                              Positioned(
                                right: -6, top: -6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$pending',
                                    style: const TextStyle(fontSize: 10, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: const Text('Pending Transfers', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/files'); // Fixed to /files as /transfers doesn't exist
                        },
                      );
                    },
                  ),
                  const Divider(color: EchoColors.pewter, thickness: 0.5),
                  _drawerItem(Icons.settings_outlined, 'Settings', () {
                    Navigator.pop(context);
                    context.push('/settings');
                  }),
                  _drawerItem(Icons.history, 'Logs', () {
                    Navigator.pop(context);
                    context.push('/logs');
                  }),
                ],
              ),
            ),
            const Divider(color: EchoColors.pewter, thickness: 0.5),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              title: const Text('Exit', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context); // close drawer first
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: EchoColors.navySlate,
                    title: const Text('Exit echoSystem?', style: TextStyle(color: Colors.white)),
                    content: const Text('All active transfers will be cancelled.', style: TextStyle(color: EchoColors.pewter)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                        child: const Text('Exit'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) SystemNavigator.pop();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? EchoColors.warmGold),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
