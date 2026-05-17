import 'dart:async';
import 'package:nsd/nsd.dart';
import '../models/device_model.dart';

class DiscoveryService {
  final String deviceId;
  final String deviceName;
  final int port;

  DiscoveryService({
    required this.deviceId,
    required this.deviceName,
    required this.port,
  });

  Stream<List<DeviceModel>> get devices => const Stream.empty();

  Future<void> start() async {
    // Stub
  }

  Future<void> stop() async {
    // Stub
  }

  void dispose() {
    stop();
  }
}
