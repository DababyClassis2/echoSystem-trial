import 'dart:async';
import 'package:nsd/nsd.dart';
import '../models/device_model.dart';

class DiscoveryService {
  static const String SERVICE_TYPE = '_echosystem._tcp.';
  final String deviceId;
  final String deviceName;
  final int port;

  NsdService? _service;
  NsdDiscovery? _discovery;
  final StreamController<List<DeviceModel>> _devicesController = StreamController<List<DeviceModel>>.broadcast();
  final Map<String, DeviceModel> _devices = {};

  DiscoveryService({
    required this.deviceId,
    required this.deviceName,
    required this.port,
  });

  Stream<List<DeviceModel>> get devices => _devicesController.stream;

  Future<void> start() async {
    await _advertise();
    await _discover();
  }

  Future<void> _advertise() async {
    final txt = {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'port': port.toString(),
    };
    _service = NsdService(
      serviceName: deviceName,
      serviceType: SERVICE_TYPE,
      port: port,
      attributes: txt,
    );
    await _service!.register();
  }

  Future<void> _discover() async {
    _discovery = NsdDiscovery(serviceType: SERVICE_TYPE);
    _discovery!.stream.listen((event) {
      final info = event.serviceInfo;
      final txt = info.attributes;
      if (info.host == null) return;
      final device = DeviceModel(
        id: txt['deviceId'] ?? info.name,
        name: txt['deviceName'] ?? info.name,
        ipAddress: info.host!,
        port: int.tryParse(txt['port'] ?? '0') ?? 0,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
      _devices[info.name] = device;
      _devicesController.add(_devices.values.toList());
    }, onError: (e) {
      // log error
    });
    await _discovery!.start();
  }

  Future<void> stop() async {
    await _service?.unregister();
    await _discovery?.stop();
    await _devicesController.close();
  }

  void dispose() {
    stop();
  }
}
