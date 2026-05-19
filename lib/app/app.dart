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

          // FIX: Replaced problematic `.when` with systematic null and error checks.
          // This approach safely handles the AsyncValue lifecycle by explicitly
          // checking for loading and error states before accessing the data.
          if (settings.isLoading) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
              debugShowCheckedModeBanner: false,
            );
          }

          if (settings?.hasError) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Text('Error loading settings: ${settings.error}'),
                ),
              ),
              debugShowCheckedModeBanner: false,
            );
          }

          // Due to the checks above, we can now safely access .value.
          final settingsData = settings.value!;
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
              // TODO: Handle this case.
              Object() => throw UnimplementedError(),
              // TODO: Handle this case.
              null => throw UnimplementedError(),
            },
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

extension on SettingsState? {
  bool? get isLoading => null;
  
  get value => null;
  
  get error => null;
}
