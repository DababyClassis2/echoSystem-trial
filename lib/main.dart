import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Global error catcher for Flutter framework
  FlutterError.onError = (FlutterErrorDetails details) {
    _writeErrorToFile(details.exceptionAsString(), details.stack);
    // Also print to console (if available)
    print(details.exceptionAsString());
    print(details.stack);
  };
  // Catch all uncaught async errors
  runZonedGuarded(() {
    runApp(const ProviderScope(child: InitializerApp()));
  }, (error, stack) {
    _writeErrorToFile(error.toString(), stack);
    print(error);
    print(stack);
  });
}

void _writeErrorToFile(String error, StackTrace? stack) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final logFile = File('${dir.path}/echosystem_crash.log');
    await logFile.writeAsString('$error\n$stack');
  } catch (e) {
    // ignore
  }
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
      setState(() { _status = 'Starting StorageService...'; });
      final storage = StorageService();
      await storage.init();

      setState(() { _status = 'Starting PermissionService...'; });
      final permission = PermissionService();
      await permission.init();

      setState(() { _status = 'All services ready. Starting app...'; });
      if (mounted) {
        // Replace this screen with the main app
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainApp(),
          ),
        );
      }
    } catch (e, stack) {
      _writeErrorToFile(e.toString(), stack);
      if (mounted) {
        setState(() {
          _error = 'Error: $e\nCheck documents directory for full log.';
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

class MainApp extends StatelessWidget {
  const MainApp({super.key});

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