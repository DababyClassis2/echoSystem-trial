import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture errors and show them on screen
  final errorNotifier = ValueNotifier<String?>(null);
  FlutterError.onError = (details) {
    errorNotifier.value = details.exceptionAsString();
    print(details.exceptionAsString());
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    errorNotifier.value = error.toString();
    return true;
  };

  runApp(
    ProviderScope(
      child: ErrorBoundary(
        errorNotifier: errorNotifier,
        child: const EchoSystemApp(),
      ),
    ),
  );
}

class ErrorBoundary extends StatelessWidget {
  final ValueNotifier<String?> errorNotifier;
  final Widget child;

  const ErrorBoundary({super.key, required this.errorNotifier, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: errorNotifier,
      builder: (context, error, _) {
        if (error != null) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.red.shade900,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        'App Error:\n$error',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return child;
      },
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
      debugShowCheckedModeBanner: true,
    );
  }
}
