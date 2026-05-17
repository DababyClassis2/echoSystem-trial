import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';

final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(ref);
});

class ProfileController {
  final Ref _ref;
  ProfileController(this._ref);

  String get deviceName => _ref.read(profileProvider).deviceName;
  int get avatarColor => _ref.read(profileProvider).avatarColor;
  bool get notificationsEnabled => _ref.read(storageServiceProvider).notificationsEnabled;

  Future<void> updateDeviceName(String name) async {
    await _ref.read(profileProvider.notifier).updateDeviceName(name);
  }

  Future<void> updateAvatarColor(int color) async {
    await _ref.read(profileProvider.notifier).updateAvatarColor(color);
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    final storage = _ref.read(storageServiceProvider);
    storage.notificationsEnabled = enabled;
  }

  Future<void> updateStoragePath(String path) async {
    final storage = _ref.read(storageServiceProvider);
    storage.defaultSavePath = path;
  }

  String get deviceId => _ref.read(storageServiceProvider).deviceId;
  String get defaultSavePath => _ref.read(storageServiceProvider).defaultSavePath;
}
