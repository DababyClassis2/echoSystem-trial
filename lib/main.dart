
import 'package:flutter/material.dart';
import 'package:echosystem/app/app.dart';
import 'package:echosystem/core/services/notification_service.dart';
import 'package:echosystem/core/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  await initBackgroundService();
  runApp(const EchoSystemApp());
}
