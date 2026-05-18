import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class DiscoveredPeer {
  final String name;
  final String address;
  final int port;
  final String platform;
  final String source;

  const DiscoveredPeer({
    required this.name,
    required this.address,
    required this.port,
    required this.platform,
    required this.source,
  });
}

class QrScanPage extends ConsumerWidget {
  const QrScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          final code = capture.barcodes.firstOrNull?.rawValue;
          if (code == null) return;
          try {
            final data = jsonDecode(code) as Map<String, dynamic>;
            final peer = DiscoveredPeer(
              name:     data['name'] as String,
              address:  data['ip']   as String,
              port:     data['port'] as int,
              platform: data['platform'] as String,
              source:   'qr',
            );
            context.pop();
            context.push('/send', extra: peer);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid QR code')));
          }
        },
      ),
    );
  }
}
