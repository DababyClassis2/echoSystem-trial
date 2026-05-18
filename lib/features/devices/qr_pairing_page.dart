import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/providers/providers.dart';

class QrPairingPage extends ConsumerWidget {
  const QrPairingPage({super.key});

  IconData _ifaceIcon(String type) {
    if (type.contains('wifi')) return Icons.wifi;
    if (type.contains('ethernet')) return Icons.settings_ethernet;
    return Icons.lan;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ifaces = ref.watch(activeInterfacesProvider);
    final profile = ref.watch(profileProvider);
    final primary = ifaces.isNotEmpty ? ifaces.first : null;

    final qrData = primary == null ? null : jsonEncode({
      'ip':       primary.address,
      'port':     56789,
      'name':     profile.deviceName,
      'platform': Platform.operatingSystem,
      'v':        1,
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Device'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan'),
            onPressed: () => context.push('/pair/scan'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.blueAccent),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Show this QR code to another device running '
                'echoSystem to connect instantly — no shared WiFi needed.',
                style: TextStyle(fontSize: 13),
              )),
            ]),
          ),
          const SizedBox(height: 32),
          if (qrData == null)
            const Text('No network interface available',
              style: TextStyle(color: Colors.redAccent))
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data:            qrData,
                version:         QrVersions.auto,
                size:            220,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
          const SizedBox(height: 24),
          if (primary != null) ...[
            Text(profile.deviceName,
              style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${primary.address} · ${primary.name}',
              style: const TextStyle(
                fontFamily: 'monospace', color: Colors.white54, fontSize: 13)),
          ],
          const SizedBox(height: 32),
          const Align(alignment: Alignment.centerLeft,
            child: Text('Active interfaces',
              style: TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          ...ifaces.map((iface) => ListTile(
            dense: true,
            leading: Icon(_ifaceIcon(iface.type), size: 18),
            title: Text(iface.name, style: const TextStyle(fontSize: 13)),
            trailing: Text(iface.address,
              style: const TextStyle(
                fontFamily: 'monospace', fontSize: 12, color: Colors.white54)),
          )),
        ]),
      ),
    );
  }
}
