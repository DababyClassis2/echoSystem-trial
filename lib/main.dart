import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/providers/providers.dart';
import 'core/services/storage_service.dart';
import 'core/services/permission_service.dart';
import 'core/network/socket_server.dart';
import 'features/transfer/incoming_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage and permissions
  final storage = StorageService();
  await storage.init();
  final permissionService = PermissionService();
  await permissionService.init();

  // Request necessary permissions at startup
  await _requestPermissions();

  // Start the socket server
  final socketServer = SocketServer();
  final serverPort = await socketServer.start();
  print('SocketServer started on port $serverPort');

  // Listen for incoming transfers and show dialog
  socketServer.onIncomingTransfer.listen((header) {
    final context = _navigatorKey.currentContext;
    if (context != null) {
      showIncomingDialog(context, header);
    }
  });

  runApp(
    ProviderScope(
      overrides: [
        // Override the socketServerProvider with the instance we started
        socketServerProvider.overrideWithValue(socketServer),
      ],
      child: const EchoSystemApp(),
    ),
  );
}

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

Future<bool> _requestPermissions() async {
  final statuses = await [
    Permission.storage,
    Permission.photos,
    Permission.videos,
    Permission.audio,
    Permission.nearbyWifiDevices,
  ].request();
  return statuses.values.every((s) => s.isGranted);
}

class EchoSystemApp extends StatelessWidget {
  const EchoSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'echoSystem',
      theme: EchoTheme.build(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
