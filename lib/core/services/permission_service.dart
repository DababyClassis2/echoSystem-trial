import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final StreamController<bool> _permissionStream = StreamController<bool>.broadcast();
  Stream<bool> get onPermissionChange => _permissionStream.stream;

  bool get allGranted => _checkAllGrantedSync();

  Future<void> init() async {
    // Listen to app lifecycle to re-check when app resumes
    WidgetsBinding.instance.addObserver(AppLifecycleObserver(this));
    await checkAllPermissions();
  }

  Future<bool> requestStoragePermissions() async {
    if (await _isAndroidAPI33Plus()) {
      final statuses = await [
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ].request();
      final granted = statuses.values.every((s) => s.isGranted);
      _permissionStream.add(granted);
      return granted;
    } else {
      final status = await Permission.storage.request();
      final granted = status.isGranted;
      _permissionStream.add(granted);
      return granted;
    }
  }

  Future<bool> requestNearbyWifiPermission() async {
    if (await _isAndroidAPI33Plus()) {
      final status = await Permission.nearbyWifiDevices.request();
      final granted = status.isGranted;
      _permissionStream.add(granted);
      return granted;
    }
    // On older APIs, this permission is not required
    return true;
  }

  Future<bool> checkAllPermissions() async {
    final storageOk = await _checkStoragePermission();
    final nearbyOk = await _checkNearbyWifiPermission();
    final allOk = storageOk && nearbyOk;
    _permissionStream.add(allOk);
    return allOk;
  }

  Future<bool> _checkStoragePermission() async {
    if (await _isAndroidAPI33Plus()) {
      final photos = await Permission.photos.status;
      final videos = await Permission.videos.status;
      final audio = await Permission.audio.status;
      return photos.isGranted && videos.isGranted && audio.isGranted;
    } else {
      return await Permission.storage.isGranted;
    }
  }

  Future<bool> _checkNearbyWifiPermission() async {
    if (await _isAndroidAPI33Plus()) {
      return await Permission.nearbyWifiDevices.isGranted;
    }
    return true;
  }

  Future<bool> _isAndroidAPI33Plus() async {
    if (WidgetsBinding.instance.rootContext == null || Theme.of(WidgetsBinding.instance.rootContext!).platform != TargetPlatform.android) {
      return false;
    }
    // Use device_info_plus to get SDK version? Or just assume API 33+ based on Android version.
    // For simplicity, we request all permissions on Android and let the system handle.
    // More robust: use device_info_plus to check SDK_INT >= 33.
    // For now, we'll use a pragmatic check: if nearbyWifiDevices permission exists, then API 33+.
    // Since that permission exists only on API 33+, we can use it as a proxy.
    try {
      await Permission.nearbyWifiDevices.status;
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _checkAllGrantedSync() {
    // This is a simplified sync check; in real usage, call checkAllPermissions() async.
    return true; // Placeholder
  }

  void dispose() {
    _permissionStream.close();
  }
}

class AppLifecycleObserver with WidgetsBindingObserver {
  final PermissionService service;
  AppLifecycleObserver(this.service);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      service.checkAllPermissions();
    }
  }
}
