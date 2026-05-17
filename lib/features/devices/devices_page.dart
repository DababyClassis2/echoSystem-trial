import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/models/device_model.dart';
import '../../core/services/network_interface_service.dart';
import '../../app/theme.dart';
import 'widgets/peer_card.dart';
import 'devices_controller.dart';

class DevicesPage extends ConsumerStatefulWidget {
  const DevicesPage({super.key});

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late Animation<double> _radarAnimation;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _radarAnimation = CurvedAnimation(
      parent: _radarController,
      curve: Curves.easeOut,
    );
    // Start scan on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoveryProvider.notifier).startScan();
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final peers = ref.watch(discoveredPeersProvider);
    final scanning = ref.watch(isDiscoveryActiveProvider);
    final ifacesAsync = ref.watch(activeInterfacesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Devices'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(discoveryProvider.notifier).restartScan(),
          ),
        ],
      ),
      body: Column(children: [
        // ── Network interface chips ──────────────────────────
        ifacesAsync.when(
          data: (ifaces) => SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: ifaces.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final iface = ifaces[i];
                final color = _ifaceColor(iface.type);
                return Chip(
                  avatar: Icon(_ifaceIcon(iface.type), size: 14, color: color),
                  label: Text(
                    '${iface.name} · ${iface.address}',
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                  backgroundColor: color.withValues(alpha: 0.1),
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                );
              },
            ),
          ),
          loading: () => const SizedBox(height: 50),
          error: (_, __) => const SizedBox(height: 50),
        ),

        // ── Radar animation ──────────────────────────────────
        SizedBox(
          height: 220,
          child: Stack(alignment: Alignment.center, children: [
            // Pulse rings
            ...List.generate(3, (i) => AnimatedBuilder(
              animation: _radarAnimation,
              builder: (_, __) {
                final delay = i * 0.33;
                final progress = (_radarAnimation.value + delay) % 1.0;
                return Container(
                  width: 200 * progress,
                  height: 200 * progress,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: EchoColors.warmGold.withValues(alpha: 1 - progress),
                      width: 1.5,
                    ),
                  ),
                );
              },
            )),
            // Centre dot
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EchoColors.warmGold,
                boxShadow: [
                  BoxShadow(
                    color: EchoColors.warmGold.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 4,
                  )
                ],
              ),
            ),
            // Peer dots on radar
            ...peers.asMap().entries.map((e) {
              final angle = (e.key * (360 / max(peers.length, 1))) * (pi / 180);
              final radius = 60.0 + (e.key % 3) * 20;
              return Positioned(
                left: 110 + radius * cos(angle) - 6,
                top: 110 + radius * sin(angle) - 6,
                child: _RadarDot(peer: e.value),
              );
            }),
          ]),
        ),

        // ── Status text ──────────────────────────────────────
        Text(
          scanning
              ? 'Scanning for devices…'
              : '${peers.length} device(s) found',
          style: TextStyle(
            color: scanning ? EchoColors.warmGold : Colors.white70,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 12),

        // ── Peer card list ────────────────────────────────────
        Expanded(
          child: peers.isEmpty
              ? _buildEmptyState(scanning)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: peers.length,
                  itemBuilder: (_, i) => _buildPeerCard(peers[i]),
                ),
        ),
      ]),
    );
  }

  Widget _buildPeerCard(DeviceModel peer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PeerCardWrapper(
        peer: peer,
        onTap: () => _showFilePicker(peer),
      ),
    );
  }

  void _showFilePicker(DeviceModel device) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: EchoColors.navySlate,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: EchoColors.pewter,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Send to ${device.displayName}',
                style: const TextStyle(color: EchoColors.icyWhite, fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final controller = ref.read(devicesControllerProvider.notifier);
                  await controller.pickAndSendFile(
                    device.id,
                    device.name,
                    device.ipAddress,
                    device.port,
                  );
                  if (mounted && ref.read(devicesControllerProvider).hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to send file')),
                    );
                  }
                },
                icon: const Icon(Icons.attach_file),
                label: const Text('Choose File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EchoColors.warmGold,
                  foregroundColor: EchoColors.deepNavy,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool scanning) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (scanning)
            const CircularProgressIndicator(color: EchoColors.warmGold)
          else ...[
            const Icon(Icons.devices_other, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('No devices found', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            const Text(
              'Make sure other devices have echoSystem open\n'
              'and are on the same network or hotspot',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ]),
      );

  Color _ifaceColor(InterfaceType type) {
    switch (type) {
      case InterfaceType.wifi: return Colors.blueAccent;
      case InterfaceType.hotspot: return Colors.orangeAccent;
      case InterfaceType.pdanet: return Colors.purpleAccent;
      case InterfaceType.vpn: return Colors.greenAccent;
      case InterfaceType.ethernet: return Colors.tealAccent;
      default: return Colors.white54;
    }
  }

  IconData _ifaceIcon(InterfaceType type) {
    switch (type) {
      case InterfaceType.wifi: return Icons.wifi;
      case InterfaceType.hotspot: return Icons.router;
      case InterfaceType.pdanet: return Icons.usb;
      case InterfaceType.vpn: return Icons.security;
      case InterfaceType.ethernet: return Icons.settings_ethernet;
      default: return Icons.network_check;
    }
  }
}

class _RadarDot extends StatelessWidget {
  final DeviceModel peer;
  const _RadarDot({required this.peer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.greenAccent,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 2,
          )
        ],
      ),
    );
  }
}

class PeerCardWrapper extends StatelessWidget {
  final DeviceModel peer;
  final VoidCallback onTap;

  const PeerCardWrapper({super.key, required this.peer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Wrap PeerCard to handle the specific onTap logic for this page
    return GestureDetector(
      onTap: onTap,
      child: PeerCard(peer: peer),
    );
  }
}
