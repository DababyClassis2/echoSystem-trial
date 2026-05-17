import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/providers.dart';
import '../../features/profile/profile_controller.dart';
import '../../app/theme.dart';
import '../../core/services/storage_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(profileProvider.notifier).load();
      }
    });
  }

  Future<String> _getLocalIp() async {
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    return ip ?? 'Not connected';
  }

  Future<int> _getServerPort() async {
    final server = ref.read(socketServerProvider);
    try {
      return await server.start();
    } catch (e) {
      return 0;
    }
  }

  Future<String> _getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }

  Future<void> _checkForUpdates() async {
    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/DababyClassis2/echoSystem-trial/releases/latest'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestTag = data['tag_name'];
        final currentInfo = await PackageInfo.fromPlatform();
        if (latestTag != 'v${currentInfo.version}') {
          if (mounted) _showUpdateDialog(data['html_url']);
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App is up to date')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not check for updates')));
    }
  }

  void _showUpdateDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EchoColors.navySlate,
        title: const Text('Update Available', style: TextStyle(color: EchoColors.icyWhite)),
        content: const Text('A new version of echoSystem is available.', style: TextStyle(color: EchoColors.pewter)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
          ElevatedButton(onPressed: () => launchUrl(Uri.parse(url)), child: const Text('View Release')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.read(storageServiceProvider);
    final profileController = ref.read(profileControllerProvider);
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('General'),
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Device Name', style: TextStyle(color: EchoColors.icyWhite)),
                  subtitle: Text(profileState.deviceName, style: const TextStyle(color: EchoColors.pewter)),
                  trailing: const Icon(Icons.edit, color: EchoColors.warmGold),
                  onTap: () => _showEditDeviceNameDialog(context, profileController),
                ),
                ListTile(
                  title: const Text('Save Location', style: TextStyle(color: EchoColors.icyWhite)),
                  subtitle: Text(storage.defaultSavePath, style: const TextStyle(color: EchoColors.pewter, fontSize: 12)),
                  trailing: const Icon(Icons.folder_open, color: EchoColors.warmGold),
                  onTap: () => _showFolderPicker(context, storage),
                ),
                SwitchListTile(
                  title: const Text('Enable Notifications', style: TextStyle(color: EchoColors.icyWhite)),
                  value: storage.notificationsEnabled,
                  onChanged: (value) {
                    storage.notificationsEnabled = value;
                    setState(() {});
                  },
                  activeThumbColor: EchoColors.warmGold,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader('App Updates'),
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: const Text('Check for Updates', style: TextStyle(color: EchoColors.icyWhite)),
              trailing: const Icon(Icons.update, color: EchoColors.warmGold),
              onTap: _checkForUpdates,
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader('Advanced'),
          Card(
            color: Colors.white.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Clear Transfer History', style: TextStyle(color: EchoColors.icyWhite)),
                  trailing: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                  onTap: () => _showClearHistoryDialog(context),
                ),
                ListTile(
                  title: const Text('Reset Device ID', style: TextStyle(color: EchoColors.icyWhite)),
                  trailing: const Icon(Icons.refresh, color: Colors.orange),
                  onTap: () => _showResetDeviceIdDialog(context, storage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDeviceNameDialog(BuildContext context, ProfileController controller) {
    final controllerText = TextEditingController(text: controller.deviceName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EchoColors.navySlate,
        title: const Text('Edit Device Name', style: TextStyle(color: EchoColors.icyWhite)),
        content: TextField(
          controller: controllerText,
          style: const TextStyle(color: EchoColors.icyWhite),
          decoration: const InputDecoration(hintText: 'Enter device name', hintStyle: TextStyle(color: EchoColors.pewter)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            if (controllerText.text.trim().isNotEmpty) {
              controller.updateDeviceName(controllerText.text);
              setState(() {});
            }
            Navigator.pop(context);
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  void _showFolderPicker(BuildContext context, StorageService storage) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null && mounted) {
      storage.defaultSavePath = result;
      setState(() {});
    }
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EchoColors.navySlate,
        title: const Text('Clear Transfer History?', style: TextStyle(color: EchoColors.icyWhite)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            ref.read(transferHistoryProvider.notifier).clearAll();
            Navigator.pop(context);
          }, child: const Text('Clear', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  void _showResetDeviceIdDialog(BuildContext context, StorageService storage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EchoColors.navySlate,
        title: const Text('Reset Device ID?', style: TextStyle(color: EchoColors.icyWhite)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            // New device ID logic here if needed
            Navigator.pop(context);
          }, child: const Text('Reset', style: TextStyle(color: Colors.orange))),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(color: EchoColors.warmGold, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
