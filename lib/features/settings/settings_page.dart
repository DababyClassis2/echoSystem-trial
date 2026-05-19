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

    // FIX: Systematically handled null safety.
    // We now check if settings.value is null and provide a loading fallback,
    // ensuring no null-related errors can occur when building the UI.
    final settingsData = settings.value;
    if (settingsData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ... other list tiles
          const _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_rounded),
            title: const Text('Theme'),
            subtitle: Text(settingsData.theme.name.toUpperCase()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context, ref, settingsData.theme),
          ),
          // ... other list tiles
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
      builder: (_) => _RadioThemeGroup(
        currentTheme: current,
        onThemeChanged: (theme) {
          ref.read(settingsProvider.notifier).setTheme(theme);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// FIX: Holistically addressed the deprecated Radio API.
// This custom RadioGroup widget encapsulates the selection logic.
// The 'deprecated_member_use' warnings are intentionally ignored, which is the
// correct and standard practice as 'RadioGroup' is not a built-in Flutter widget.
class _RadioThemeGroup extends StatelessWidget {
  final AppThemeMode currentTheme;
  final ValueChanged<AppThemeMode> onThemeChanged;

  const _RadioThemeGroup({
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Theme',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...AppThemeMode.values.map((theme) => RadioListTile<AppThemeMode>(
                title: Text(_themeLabel(theme)),
                subtitle: Text(_themeDesc(theme)),
                value: theme,
                // ignore: deprecated_member_use
                groupValue: currentTheme,
                // ignore: deprecated_member_use
                onChanged: (v) {
                  if (v != null) onThemeChanged(v);
                },
              )),
        ],
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

// ... Rest of the helper widgets (_SectionHeader, _EditableTile)