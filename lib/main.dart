import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/permission_service.dart';

import 'core/services/background_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initBackgroundService();
  await FlutterBackgroundService().startService();
  runApp(const ProviderScope(child: InitializerApp()));
}

class InitializerApp extends StatelessWidget {
  const InitializerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'echoSystem',
      theme: EchoTheme.build(),
      home: const InitializerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InitializerScreen extends StatefulWidget {
  const InitializerScreen({super.key});

  @override
  State<InitializerScreen> createState() => _InitializerScreenState();
}

class _InitializerScreenState extends State<InitializerScreen> {
  String _status = 'Initializing...';
  String _error = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _status = 'Starting StorageService...';
      });
      final storage = StorageService();
      await storage.init().timeout(const Duration(seconds: 10));
      setState(() {
        _status = 'Starting PermissionService...';
      });
      final permission = PermissionService();
      await permission.init().timeout(const Duration(seconds: 5));
      setState(() {
        _status = 'All services ready. Starting app...';
      });
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const EchoSystemApp(),
        ),
      );
    } catch (e, stack) {
      try {
        final dir = await getExternalStorageDirectory();
        final logFile = File('${dir?.path}/echoSystem_crash.log');
        await logFile.writeAsString('$e\n$stack');
        _error = 'Error: $e\nLog saved to ${logFile.path}';
      } catch (logError) {
        _error = 'Error: $e\n(Also failed to write log: $logError)';
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(_status),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 20),
                  Text(_error, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = '';
                        _status = 'Retrying...';
                      });
                      _initialize();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }
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
