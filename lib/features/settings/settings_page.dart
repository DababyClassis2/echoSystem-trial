import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/settings_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── IDENTITY ────────────────────────────────
          const _SectionHeader('Identity'),
          _EditableTile(
            icon: Icons.badge_rounded,
            title: 'Device Name',
            value: settings.deviceName,
            onSave: (v) => ref.read(settingsProvider.notifier).setDeviceName(v),
          ),

          // ── APPEARANCE ──────────────────────────────
          const _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_rounded),
            title: const Text('Theme'),
            subtitle: Text(settings.theme.name.toUpperCase()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, ref, settings.theme),
          ),

          // ── TRANSFERS ───────────────────────────────
          const _SectionHeader('Transfers'),
          ListTile(
            leading: const Icon(Icons.folder_rounded),
            title: const Text('Save Location'),
            subtitle: Text(settings.saveFolder ?? 'Default Downloads'),
            trailing: const Icon(Icons.edit_rounded, size: 18),
            onTap: () async {
              final dir = await FilePicker.platform.getDirectoryPath();
              if (dir != null) {
                ref.read(settingsProvider.notifier).setSaveFolder(dir);
              }
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.bolt_rounded),
            title: const Text('Auto-accept transfers'),
            subtitle: const Text('From known devices only'),
            value: settings.autoAccept,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setAutoAccept(v),
          ),
          ListTile(
            leading: const Icon(Icons.layers_rounded),
            title: const Text('Max concurrent transfers'),
            trailing: DropdownButton<int>(
              value: settings.maxConcurrent,
              underline: const SizedBox(),
              items: [1, 2, 3, 5, 10]
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setMaxConcurrent(v!),
            ),
          ),

          // ── NETWORK ─────────────────────────────────
          const _SectionHeader('Network'),
          ListTile(
            leading: const Icon(Icons.hub_rounded),
            title: const Text('Discovery Mode'),
            subtitle: const Text(
                'Auto detects WiFi, hotspot, PdaNet, VPN interfaces'),
            trailing: DropdownButton<String>(
              value: settings.networkMode,
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem(value: 'auto', child: Text('Auto')),
                const DropdownMenuItem(value: 'wifi', child: Text('WiFi Only')),
                const DropdownMenuItem(value: 'hotspot', child: Text('Hotspot Only')),
                const DropdownMenuItem(value: 'any', child: Text('Any Interface')),
              ],
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setNetworkMode(v!),
            ),
          ),

          // ── ABOUT ───────────────────────────────────
          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (_, snap) => Text(
                snap.hasData
                    ? 'v${snap.data!.version}+${snap.data!.buildNumber}'
                    : '—',
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(
      BuildContext context, WidgetRef ref, AppThemeMode current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Theme',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...AppThemeMode.values.map((t) => RadioListTile<AppThemeMode>(
                  title: Text(_themeLabel(t)),
                  subtitle: Text(_themeDesc(t)),
                  value: t,
                  groupValue: current,
                  onChanged: (v) {
                    ref.read(settingsProvider.notifier).setTheme(v!);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  String _themeLabel(AppThemeMode t) => switch (t) {
        AppThemeMode.light => '☀️  Light',
        AppThemeMode.dark => '🌙  Dark',
        AppThemeMode.amoled => '⬛  AMOLED Black',
        AppThemeMode.system => '🔄  Follow System',
      };

  String _themeDesc(AppThemeMode t) => switch (t) {
        AppThemeMode.amoled => 'Pure black — saves battery on OLED screens',
        AppThemeMode.system => 'Matches your device theme',
        _ => '',
      };
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title,
          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
    );
  }
}

class _EditableTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final ValueChanged<String> onSave;
  const _EditableTile({required this.icon, required this.title, required this.value, required this.onSave});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit_rounded, size: 18),
      onTap: () {
        final controller = TextEditingController(text: value);
        showDialog(context: context, builder: (_) => AlertDialog(
          title: Text(title),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () { onSave(controller.text); Navigator.pop(context); }, child: const Text('Save')),
          ],
        ));
      },
    );
  }
}
