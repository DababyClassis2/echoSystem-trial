import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/models/device_model.dart';

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
            final peer = DeviceModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: data['name'] as String,
              ipAddress: data['ip'] as String,
              port: data['port'] as int,
              lastSeen: DateTime.now(),
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
