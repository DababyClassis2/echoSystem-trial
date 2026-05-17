import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, amoled, system }

class SettingsService {
  static const _kTheme = 'app_theme';
  static const _kDeviceName = 'device_name';
  static const _kSaveFolder = 'save_folder';
  static const _kAutoAccept = 'auto_accept';
  static const _kNetworkMode = 'network_mode';
  static const _kMaxTransfers = 'max_concurrent';

  final SharedPreferences _prefs;
  const SettingsService(this._prefs);

  AppThemeMode get theme =>
      AppThemeMode.values.byName(_prefs.getString(_kTheme) ?? 'dark');
  Future<void> setTheme(AppThemeMode t) => _prefs.setString(_kTheme, t.name);

  String get deviceName => _prefs.getString(_kDeviceName) ?? _defaultName();
  Future<void> setDeviceName(String n) => _prefs.setString(_kDeviceName, n);

  String? get saveFolder => _prefs.getString(_kSaveFolder);
  Future<void> setSaveFolder(String p) => _prefs.setString(_kSaveFolder, p);

  bool get autoAccept => _prefs.getBool(_kAutoAccept) ?? false;
  Future<void> setAutoAccept(bool v) => _prefs.setBool(_kAutoAccept, v);

  String get networkMode => _prefs.getString(_kNetworkMode) ?? 'auto';
  Future<void> setNetworkMode(String m) => _prefs.setString(_kNetworkMode, m);

  int get maxConcurrent => _prefs.getInt(_kMaxTransfers) ?? 3;
  Future<void> setMaxConcurrent(int v) => _prefs.setInt(_kMaxTransfers, v);

  String _defaultName() {
    return 'Echo-${Platform.localHostname.split('.').first}';
  }
}
