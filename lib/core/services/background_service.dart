import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      isForegroundMode: true,
      notificationChannelId: 'echosystem_transfers',
      initialNotificationTitle: 'echoSystem',
      initialNotificationContent: 'Ready to transfer files',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onServiceStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  // Listen for transfer progress events from main isolate
  service.on('transfer_progress').listen((data) async {
    if (data == null) return;
    final id = data['id'] as String;
    final fileName = data['fileName'] as String;
    final progress = (data['progress'] as num).toDouble();
    final speed = data['speed'] as String;

    await notifications.show(
      id.hashCode,
      'Transferring: $fileName',
      '${(progress * 100).toStringAsFixed(0)}% · $speed',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'echosystem_transfers',
          'File Transfers',
          channelDescription: 'echoSystem file transfer progress',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: 100,
          progress: (progress * 100).toInt(),
          onlyAlertOnce: true,
          ongoing: true,
        ),
      ),
    );
  });

  service.on('transfer_complete').listen((data) async {
    if (data == null) return;
    await notifications.show(
      data['id'].hashCode + 1,
      '✅ Transfer Complete',
      data['fileName'] as String,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'echosystem_transfers',
          'File Transfers',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  });

  service.on('incoming_request').listen((data) async {
    if (data == null) return;
    // Show accept/decline notification with actions
    await notifications.show(
      999,
      '📥 Incoming: ${data['fileName']}',
      'From ${data['peerName']} · ${data['fileSize']}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'echosystem_incoming',
          'Incoming Requests',
          importance: Importance.max,
          priority: Priority.max,
          actions: [
            AndroidNotificationAction('accept', 'Accept', showsUserInterface: true),
            AndroidNotificationAction('decline', 'Decline'),
          ],
        ),
      ),
    );
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async => true;
