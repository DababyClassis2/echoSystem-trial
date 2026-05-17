import 'dart:async';
import 'package:nsd/nsd.dart';
import '../models/device_model.dart';

class DiscoveryService {
  static const String SERVICE_TYPE = '_echosystem._tcp.';
  final String deviceId;
  final String deviceName;
  final int port;

  Nsd? _nsd;
  String? _registrationId;
  StreamController<List<DeviceModel>> _devicesController =
      StreamController<List<DeviceModel>>.broadcast();
  final Map<String, DeviceModel> _devices = {};

  DiscoveryService({
    required this.deviceId,
    required this.deviceName,
    required this.port,
  });

  Stream<List<DeviceModel>> get devices => _devicesController.stream;

  Future<void> start() async {
    _nsd = Nsd();
    await _nsd!.init();
    await _advertise();
    await _discover();
  }

  Future<void> _advertise() async {
    final txt = {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'port': port.toString(),
    };
    _registrationId = await _nsd!.registerService(
      SERVICE_TYPE,
      deviceName,
      port,
      txt,
    );
  }

  Future<void> _discover() async {
    _nsd!.discoverServices(SERVICE_TYPE).listen((NsdServiceInfo info) {
      final existing = _devices[info.name];
      if (existing != null && existing.ipAddress == info.host) {
        return; // no change
      }
      if (info.host == null) return; // invalid
      final device = DeviceModel(
        id: info.txt['deviceId'] ?? info.name,
        name: info.txt['deviceName'] ?? info.name,
        ipAddress: info.host!,
        port: int.tryParse(info.txt['port'] ?? '0') ?? 0,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
      _devices[info.name] = device;
      _devicesController.add(_devices.values.toList());
    }, onError: (e) {
      // log error but don't crash
    });
  }

  Future<void> stop() async {
    if (_registrationId != null) {
      await _nsd?.unregisterService(_registrationId!);
    }
    await _nsd?.stopDiscovery();
    await _nsd?.close();
    _devicesController.close();
  }

  void dispose() {
    stop();
  }
}
