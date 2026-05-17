import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../app/theme.dart';
import '../../shared/widgets/glassmorphic_card.dart';
import 'devices_controller.dart';
import '../../core/models/device_model.dart';

class DevicesPage extends ConsumerStatefulWidget {
  const DevicesPage({super.key});

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage> {
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    ref.read(discoveryServiceWithPortProvider.future).then((_) {
      if (!_disposed && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(discoveredDevicesFromServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.invalidate(discoveryServiceWithPortProvider);
        },
        backgroundColor: EchoColors.warmGold,
        child: const Icon(Icons.refresh),
      ),
      body: devicesAsync.when(
        data: (devices) {
          if (devices.isEmpty) {
            return const Center(
              child: GlassmorphicCard(
                title: 'No Devices Found',
                content: 'Make sure other devices are running echoSystem and connected to the same Wi-Fi network.\n\nTap refresh to scan again.',
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return _DeviceTile(
                device: device,
                onTap: () => _showFilePicker(device),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: GlassmorphicCard(
            title: 'Discovery Error',
            content: err.toString(),
          ),
        ),
      ),
    );
  }

  void _showFilePicker(DeviceModel device) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: EchoColors.navySlate,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
}

class _DeviceTile extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onTap;

  const _DeviceTile({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(device.avatarColor),
          child: Text(device.name.substring(0, 1).toUpperCase()),
        ),
        title: Text(device.name, style: const TextStyle(color: EchoColors.icyWhite)),
        subtitle: Text(device.ipAddress, style: const TextStyle(color: EchoColors.pewter)),
        trailing: const Icon(Icons.send, color: EchoColors.warmGold),
        onTap: onTap,
      ),
    );
  }
}
