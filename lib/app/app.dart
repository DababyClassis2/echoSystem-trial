import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

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
