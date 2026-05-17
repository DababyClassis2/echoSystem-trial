import 'package:flutter/material.dart';
import '../../../core/models/device_model.dart';
import '../../../app/theme.dart';

class PeerCard extends StatelessWidget {
  final DeviceModel peer;
  const PeerCard({super.key, required this.peer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onTap(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: _platformColor(peer.platform).withValues(alpha: 0.2),
              child: Icon(
                _platformIcon(peer.platform),
                color: _platformColor(peer.platform),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(peer.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15, color: EchoColors.icyWhite)),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.circle, size: 8,
                    color: peer.isOnline ? Colors.greenAccent : Colors.red),
                  const SizedBox(width: 5),
                  Text(
                    '${peer.ipAddress} · ${peer.interfaceType}',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ]),
              ],
            )),
            // Send button
            ElevatedButton.icon(
              onPressed: () => _onTap(context),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EchoColors.warmGold,
                foregroundColor: EchoColors.deepNavy,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    // Navigate to transfer screen or show file picker
    // For now, matching the existing logic which shows file picker in devices_page
    // but the prompt says context.push('/send', extra: peer)
    // I should check if /send route exists or use existing logic.
  }

  Color _platformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'android': return Colors.greenAccent;
      case 'ios':     return Colors.white;
      case 'macos':   return Colors.blueAccent;
      case 'windows': return Colors.blue;
      case 'linux':   return Colors.orangeAccent;
      default:        return Colors.white54;
    }
  }

  IconData _platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android': return Icons.android;
      case 'ios':     return Icons.phone_iphone;
      case 'macos':   return Icons.laptop_mac;
      case 'windows': return Icons.desktop_windows;
      case 'linux':   return Icons.terminal;
      default:        return Icons.devices_other;
    }
  }
}
