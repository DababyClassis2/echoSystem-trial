import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_page.dart';
import '../features/files/files_page.dart';
import '../features/devices/devices_page.dart';
import '../features/profile/profile_page.dart';
import '../features/settings/settings_page.dart';
import '../features/logs/logs_page.dart';
import '../features/transfers/active_transfer_page.dart';
import '../shared/widgets/shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(path: '/home', name: 'home', builder: (_, __) => const HomePage()),
        GoRoute(path: '/files', name: 'files', builder: (_, __) => const FilesPage()),
        GoRoute(path: '/devices', name: 'devices', builder: (_, __) => const DevicesPage()),
        GoRoute(path: '/profile', name: 'profile', builder: (_, __) => const ProfilePage()),
      ],
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const SettingsPage(),
    ),
    GoRoute(
      path: '/logs',
      name: 'logs',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const LogsPage(),
    ),
    GoRoute(
      path: '/transfers/active',
      name: 'activeTransfers',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const ActiveTransferPage(),
    ),
  ],
);
