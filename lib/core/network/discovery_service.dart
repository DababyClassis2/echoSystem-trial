import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart';
import '../models/device_model.dart';
import '../services/network_interface_service.dart';

class DiscoveryService {
  final String deviceId;
  final String deviceName;
  final int port;

  DiscoveryService({
    required this.deviceId,
    required this.deviceName,
    required this.port,
  });

  final _deviceController = StreamController<List<DeviceModel>>.broadcast();
  Stream<List<DeviceModel>> get devices => _deviceController.stream;

  Discovery? _discovery;
  Registration? _registration;
  final Map<String, DeviceModel> _discoveredDevices = {};

  Future<void> start() async {
    final interfaces = await NetworkInterfaceService.getActiveInterfaces();
    if (interfaces.isEmpty) {
      debugPrint('[Discovery] No usable network interfaces found');
      return;
    }

    // Use the highest priority interface for NSD registration info
    final primary = interfaces.first;
    debugPrint('[Discovery] Advertising on ${primary.name} (${primary.address})');

    // Register service
    _registration = await register(Service(
      name: deviceName,
      type: '_echosystem._tcp',
      port: port,
      txt: {
        'id': utf8.encode(deviceId),
        'ip': utf8.encode(primary.address),
        'version': utf8.encode('1'),
        'platform': utf8.encode(Platform.operatingSystem),
        'interface': utf8.encode(primary.name),
      },
    ));

    // Start discovery
    _discovery = await startDiscovery('_echosystem._tcp');

    _discovery!.addListener(() {
      for (final service in _discovery!.services) {
        final txt = service.txt;
        final id = txt?['id'] != null ? utf8.decode(txt!['id']!) : service.name;
        if (id == deviceId) continue; // Skip self

        final device = DeviceModel(
          id: id!,
          name: service.name ?? 'Unknown',
          ipAddress: txt?['ip'] != null ? utf8.decode(txt!['ip']!) : (service.addresses?.first.address ?? '0.0.0.0'),
          port: service.port ?? 0,
          isOnline: true,
          avatarColor: 0xFF4A5B6E, // Default
          lastSeen: DateTime.now(),
          platform: txt?['platform'] != null ? utf8.decode(txt!['platform']!) : 'unknown',
          interfaceType: txt?['interface'] != null ? utf8.decode(txt!['interface']!) : 'unknown',
        );

        _discoveredDevices[device.id] = device;
        _deviceController.add(_discoveredDevices.values.toList());
      }
    });

    // Also broadcast on secondary interfaces (hotspot bridge scenario)
    for (final iface in interfaces.skip(1)) {
      debugPrint('[Discovery] Secondary interface available: ${iface.name} (${iface.address})');
    }
  }

  Future<void> stop() async {
    if (_registration != null) {
      await unregister(_registration!);
      _registration = null;
    }
    if (_discovery != null) {
      await stopDiscovery(_discovery!);
      _discovery = null;
    }
    _discoveredDevices.clear();
    _deviceController.add([]);
  }

  void dispose() {
    stop();
    _deviceController.close();
  }
}
