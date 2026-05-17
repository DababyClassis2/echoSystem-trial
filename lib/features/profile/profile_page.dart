import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../app/theme.dart';
import '../../core/providers/providers.dart';
import 'profile_controller.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late Future<String> _ipAddress;
  late Future<String> _deviceModel;
  late Future<String> _appVersion;

  @override
  void initState() {
    super.initState();
    _ipAddress = _getIpAddress();
    _deviceModel = _getDeviceModel();
    _appVersion = _getAppVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(profileProvider.notifier).load();
      }
    });
  }

  Future<String> _getIpAddress() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    return ip ?? 'Not connected to Wi-Fi';
  }

  Future<String> _getDeviceModel() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    }
    return 'Unknown';
  }

  Future<String> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final controller = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Avatar Color', style: TextStyle(color: EchoColors.warmGold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: EchoColors.avatarPalette.map((color) {
                      return GestureDetector(
                        onTap: () => controller.updateAvatarColor(color),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(color),
                          child: profileState.avatarColor == color
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Device Name', style: TextStyle(color: EchoColors.warmGold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: profileState.deviceName,
                    decoration: const InputDecoration(
                      hintText: 'Enter device name',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(color: EchoColors.icyWhite),
                    onFieldSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        controller.updateDeviceName(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Save Location', style: TextStyle(color: EchoColors.warmGold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          controller.defaultSavePath,
                          style: const TextStyle(color: EchoColors.pewter, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.folder_open, color: EchoColors.warmGold),
                        onPressed: () async {
                          final result = await FilePicker.platform.getDirectoryPath();
                          if (result != null && mounted) {
                            controller.updateStoragePath(result);
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: const Text('Enable Notifications', style: TextStyle(color: EchoColors.icyWhite)),
              value: controller.notificationsEnabled,
              onChanged: (value) {
                controller.updateNotificationsEnabled(value);
                setState(() {});
              },
              activeColor: EchoColors.warmGold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Device Information', style: TextStyle(color: EchoColors.warmGold, fontSize: 16)),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: _ipAddress,
                    builder: (context, snapshot) => ListTile(
                      title: const Text('IP Address', style: TextStyle(color: EchoColors.pewter)),
                      trailing: Text(snapshot.data ?? 'Loading...', style: const TextStyle(color: EchoColors.icyWhite)),
                    ),
                  ),
                  FutureBuilder<String>(
                    future: _deviceModel,
                    builder: (context, snapshot) => ListTile(
                      title: const Text('Device Model', style: TextStyle(color: EchoColors.pewter)),
                      trailing: Text(snapshot.data ?? 'Loading...', style: const TextStyle(color: EchoColors.icyWhite)),
                    ),
                  ),
                  ListTile(
                    title: const Text('Device ID', style: TextStyle(color: EchoColors.pewter)),
                    trailing: Text(controller.deviceId.substring(0, 8), style: const TextStyle(color: EchoColors.icyWhite)),
                  ),
                  FutureBuilder<String>(
                    future: _appVersion,
                    builder: (context, snapshot) => ListTile(
                      title: const Text('App Version', style: TextStyle(color: EchoColors.pewter)),
                      trailing: Text(snapshot.data ?? 'Loading...', style: const TextStyle(color: EchoColors.icyWhite)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
