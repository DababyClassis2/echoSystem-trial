import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkInterfaceInfo {
  final String name;
  final String address;
  final String subnet;
  final InterfaceType type;
  const NetworkInterfaceInfo({
    required this.name,
    required this.address,
    required this.subnet,
    required this.type,
  });
}

enum InterfaceType { wifi, hotspot, pdanet, vpn, ethernet, unknown }

class NetworkInterfaceService {
  /// Returns ALL active IPv4 interfaces, ranked by usability.
  /// Hotspot/PdaNet/VPN interfaces are included — this is the fix
  /// that makes discovery work even when a VPN or USB tether is active.
  static Future<List<NetworkInterfaceInfo>> getActiveInterfaces() async {
    final results = <NetworkInterfaceInfo>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          results.add(NetworkInterfaceInfo(
            name:    iface.name,
            address: addr.address,
            subnet:  _subnetFrom(addr.address),
            type:    _classifyInterface(iface.name, addr.address),
          ));
        }
      }
    } catch (e) {
      debugPrint('[NetworkInterfaceService] error: $e');
    }
    // Sort: wifi first, then hotspot, then VPN, then unknown
    results.sort((a, b) => a.type.index.compareTo(b.type.index));
    return results;
  }

  static String _subnetFrom(String ip) {
    final parts = ip.split('.');
    if (parts.length < 3) return ip;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  static InterfaceType _classifyInterface(String name, String ip) {
    final n = name.toLowerCase();
    if (n.contains('wlan') || n.contains('wifi') || n.contains('en0')) {
      return InterfaceType.wifi;
    }
    if (n.contains('ap') || n.contains('softap') || ip.startsWith('192.168.43')) {
      return InterfaceType.hotspot;
    }
    if (n.contains('rndis') || n.contains('bt-pan') || ip.startsWith('192.168.42')) {
      return InterfaceType.pdanet;
    }
    if (n.contains('tun') || n.contains('tap') || n.contains('pptp') ||
        n.contains('vpn') || n.contains('wg')) {
      return InterfaceType.vpn;
    }
    if (n.contains('eth') || n.contains('en1')) {
      return InterfaceType.ethernet;
    }
    return InterfaceType.unknown;
  }
}
