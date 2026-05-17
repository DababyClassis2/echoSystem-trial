import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/settings_service.dart';

// --- Settings state model ---
class SettingsState {
  final AppThemeMode theme;
  final String deviceName;
  final String? saveFolder;
  final bool autoAccept;
  final String networkMode;
  final int maxConcurrent;

  const SettingsState({
    required this.theme,
    required this.deviceName,
    required this.saveFolder,
    required this.autoAccept,
    required this.networkMode,
    required this.maxConcurrent,
  });

  SettingsState copyWith({
    AppThemeMode? theme,
    String? deviceName,
    String? saveFolder,
    bool? autoAccept,
    String? networkMode,
    int? maxConcurrent,
  }) {
    return SettingsState(
      theme: theme ?? this.theme,
      deviceName: deviceName ?? this.deviceName,
      saveFolder: saveFolder ?? this.saveFolder,
      autoAccept: autoAccept ?? this.autoAccept,
      networkMode: networkMode ?? this.networkMode,
      maxConcurrent: maxConcurrent ?? this.maxConcurrent,
    );
  }
}

// --- Settings provider ---
final settingsServiceProvider = FutureProvider<SettingsService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return SettingsService(prefs);
});

class SettingsNotifier extends StateNotifier<SettingsState?> {
  final Ref ref;
  SettingsNotifier(this.ref) : super(null) {
    _init();
  }

  Future<void> _init() async {
    final service = await ref.read(settingsServiceProvider.future);
    state = SettingsState(
      theme: service.theme,
      deviceName: service.deviceName,
      saveFolder: service.saveFolder,
      autoAccept: service.autoAccept,
      networkMode: service.networkMode,
      maxConcurrent: service.maxConcurrent,
    );
  }

  Future<void> setTheme(AppThemeMode theme) async {
    final service = await ref.read(settingsServiceProvider.future);
    await service.setTheme(theme);
    state = state?.copyWith(theme: theme);
  }

  Future<void> setDeviceName(String name) async {
    final service = await ref.read(settingsServiceProvider.future);
    await service.setDeviceName(name);
    state = state?.copyWith(deviceName: name);
  }

  Future<void> setSaveFolder(String path) async {
    final service = await ref.read(settingsServiceProvider.future);
    await service.setSaveFolder(path);
    state = state?.copyWith(saveFolder: path);
  }

  Future<void> setAutoAccept(bool value) async {
    final service = await ref.read(settingsServiceProvider.future);
    await service.setAutoAccept(value);
    state = state?.copyWith(autoAccept: value);
  }

  Future<void> setNetworkMode(String mode) async {
    final service = await ref.read(settingsServiceProvider.future);
    await service.setNetworkMode(mode);
    state = state?.copyWith(networkMode: mode);
  }

  Future<void> setMaxConcurrent(int value) async {
    final service = await ref.read(settingsServiceProvider.future);
    await service.setMaxConcurrent(value);
    state = state?.copyWith(maxConcurrent: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState?>((ref) {
  return SettingsNotifier(ref);
});
