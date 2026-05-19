
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'router.dart';
import '../core/providers/settings_provider.dart';
import '../core/services/settings_service.dart';

class EchoSystemApp extends StatelessWidget {
  const EchoSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(settingsProvider);

          return settings.when(
            data: (settingsData) {
              final theme = settingsData.theme;

              return MaterialApp.router(
                title: 'echoSystem',
                theme: FlexThemeData.light(scheme: FlexScheme.aquaBlue),
                darkTheme: theme == AppThemeMode.amoled
                    ? FlexThemeData.dark(scheme: FlexScheme.aquaBlue)
                        .copyWith(scaffoldBackgroundColor: Colors.black)
                    : FlexThemeData.dark(scheme: FlexScheme.aquaBlue),
                themeMode: switch (theme) {
                  AppThemeMode.light => ThemeMode.light,
                  AppThemeMode.dark => ThemeMode.dark,
                  AppThemeMode.amoled => ThemeMode.dark,
                  AppThemeMode.system => ThemeMode.system,
                },
                routerConfig: appRouter,
                debugShowCheckedModeBanner: false,
              );
            },
            loading: () => const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
              debugShowCheckedModeBanner: false,
            ),
            error: (error, stackTrace) => MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text('Error loading settings: $error'),
                ),
              ),
              debugShowCheckedModeBanner: false,
            ),
          );
        },
      ),
    );
  }
}
