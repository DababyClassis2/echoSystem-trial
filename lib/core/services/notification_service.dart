import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(const InitializationSettings(android: android));
    await _createChannels();
  }

  Future<void> _createChannels() async {
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'echosystem_transfers',
        'Transfers',
        description: 'Notifications for file transfers.',
        importance: Importance.low,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'echosystem_incoming',
        'Incoming Files',
        description: 'Notifications for incoming files.',
        importance: Importance.defaultImportance,
      ),
    );
  }
}
