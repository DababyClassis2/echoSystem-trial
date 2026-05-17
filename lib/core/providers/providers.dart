import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';
import '../network/discovery_service.dart';
import '../network/socket_server.dart';
import '../network/transfer_service.dart';
import '../models/device_model.dart';
import '../models/transfer_model.dart';

// --- Singleton Services ---
final storageServiceProvider = Provider<StorageService>((ref) {
  final service = StorageService();
  service.init();
  return service;
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  final service = PermissionService();
  service.init();
  return service;
});

final socketServerProvider = Provider<SocketServer>((ref) {
  return SocketServer();
});

final transferServiceProvider = Provider<TransferService>((ref) {
  return TransferService();
});

// --- StateNotifier for discovered devices ---
class DevicesNotifier extends StateNotifier<List<DeviceModel>> {
  DevicesNotifier(this.ref) : super([]);
  final Ref ref;

  void updateDevices(List<DeviceModel> devices) {
    state = devices;
  }

  void addDevice(DeviceModel device) {
    final existing = state.indexWhere((d) => d.id == device.id);
    if (existing != -1) {
      state = [...state]..[existing] = device;
    } else {
      state = [...state, device];
    }
  }

  void removeDevice(String id) {
    state = state.where((d) => d.id != id).toList();
  }
}

final devicesProvider = StateNotifierProvider<DevicesNotifier, List<DeviceModel>>((ref) {
  return DevicesNotifier(ref);
});

// --- StateNotifier for transfer history ---
class TransferHistoryNotifier extends StateNotifier<AsyncValue<List<TransferModel>>> {
  TransferHistoryNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadFromStorage();
  }
  final Ref ref;

  void loadFromStorage() {
    try {
      final storage = ref.read(storageServiceProvider);
      state = AsyncValue.data(storage.transferHistory);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransfer(TransferModel transfer) async {
    final storage = ref.read(storageServiceProvider);
    await storage.addTransfer(transfer);
    final current = state.value ?? [];
    state = AsyncValue.data([...current, transfer]);
  }

  Future<void> updateTransfer(TransferModel transfer) async {
    final storage = ref.read(storageServiceProvider);
    await storage.updateTransfer(transfer);
    final current = state.value ?? [];
    final index = current.indexWhere((t) => t.id == transfer.id);
    if (index != -1) {
      final newList = [...current];
      newList[index] = transfer;
      state = AsyncValue.data(newList);
    } else {
      state = AsyncValue.data([...current, transfer]);
    }
  }

  Future<void> deleteTransfer(String id) async {
    final storage = ref.read(storageServiceProvider);
    await storage.deleteTransfer(id);
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((t) => t.id != id).toList());
  }

  Future<void> clearAll() async {
    final storage = ref.read(storageServiceProvider);
    await storage.clearTransferHistory();
    state = const AsyncValue.data([]);
  }
}

final transferHistoryProvider = StateNotifierProvider<TransferHistoryNotifier, AsyncValue<List<TransferModel>>>((ref) {
  return TransferHistoryNotifier(ref);
});

// --- StateNotifier for active transfers (in-progress) ---
class ActiveTransfersNotifier extends StateNotifier<List<TransferModel>> {
  ActiveTransfersNotifier() : super([]);

  void add(TransferModel transfer) {
    state = [...state, transfer];
  }

  void update(TransferModel transfer) {
    final index = state.indexWhere((t) => t.id == transfer.id);
    if (index != -1) {
      state = [...state]..[index] = transfer;
    }
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  void clear() {
    state = [];
  }
}

final activeTransfersProvider = StateNotifierProvider<ActiveTransfersNotifier, List<TransferModel>>((ref) {
  return ActiveTransfersNotifier();
});

// --- Profile state (device name, avatar color) ---
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this.ref) : super(const ProfileState());
  final Ref ref;

  void load() {
    final storage = ref.read(storageServiceProvider);
    state = ProfileState(
      deviceName: storage.deviceName,
      avatarColor: storage.avatarColor,
    );
  }

  Future<void> updateDeviceName(String name) async {
    final storage = ref.read(storageServiceProvider);
    storage.deviceName = name;
    state = state.copyWith(deviceName: name);
  }

  Future<void> updateAvatarColor(int color) async {
    final storage = ref.read(storageServiceProvider);
    storage.avatarColor = color;
    state = state.copyWith(avatarColor: color);
  }
}

class ProfileState {
  final String deviceName;
  final int avatarColor;
  const ProfileState({this.deviceName = '', this.avatarColor = 0xFF4A5B6E});

  ProfileState copyWith({String? deviceName, int? avatarColor}) {
    return ProfileState(
      deviceName: deviceName ?? this.deviceName,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});

// --- Permissions stream provider ---
final permissionsGrantedProvider = StreamProvider<bool>((ref) {
  final permService = ref.watch(permissionServiceProvider);
  return permService.onPermissionChange;
});

// --- Socket server port provider (future) ---
final socketServerPortProvider = FutureProvider<int>((ref) async {
  final server = ref.watch(socketServerProvider);
  final port = await server.start();
  return port;
});

// --- Combined: DiscoveryService that depends on socketServerPortProvider ---
final discoveryServiceWithPortProvider = FutureProvider<DiscoveryService>((ref) async {
  final port = await ref.watch(socketServerPortProvider.future);
  final storage = ref.watch(storageServiceProvider);
  final deviceId = storage.deviceId;
  final deviceName = storage.deviceName;
  final discovery = DiscoveryService(
    deviceId: deviceId,
    deviceName: deviceName,
    port: port,
  );
  await discovery.start();
  ref.onDispose(() {
    discovery.dispose();
  });
  return discovery;
});

final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  return ref.watch(discoveryServiceWithPortProvider).value!;
});

// --- Helper: watch discovered devices from the future provider ---
final discoveredDevicesFromServiceProvider = StreamProvider<List<DeviceModel>>((ref) {
  return Stream<List<DeviceModel>>.empty();
});
