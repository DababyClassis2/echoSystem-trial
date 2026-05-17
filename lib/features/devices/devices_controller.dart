import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/file_item_model.dart';
import '../../core/models/transfer_model.dart';
import '../../core/providers/providers.dart';
import '../../core/models/device_model.dart';

final devicesControllerProvider = StateNotifierProvider<DevicesController, AsyncValue<void>>((ref) {
  return DevicesController(ref);
});

class DevicesController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  DevicesController(this._ref) : super(const AsyncValue.data(null));

  Future<void> pickAndSendFile(String targetDeviceId, String targetDeviceName, String targetIp, int targetPort) async {
    state = const AsyncValue.loading();
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) {
        state = const AsyncValue.data(null);
        return;
      }
      final filePath = result.files.single.path!;
      final fileItem = await FileItemModel.fromPath(filePath);
      final transferId = const Uuid().v4();
      final storage = _ref.read(storageServiceProvider);
      final senderId = storage.deviceId;
      final senderName = storage.deviceName;

      // Create transfer record
      final transfer = TransferModel(
        id: transferId,
        fileName: fileItem.name,
        fileSizeBytes: fileItem.sizeBytes,
        transferredBytes: 0,
        status: TransferStatus.pending.name,
        direction: TransferDirection.sending.name,
        peerId: targetDeviceId,
        peerName: targetDeviceName,
        startedAt: DateTime.now(),
      );
      await _ref.read(transferHistoryProvider.notifier).addTransfer(transfer);
      _ref.read(activeTransfersProvider.notifier).add(transfer);

      // Send file
      final transferService = _ref.read(transferServiceProvider);
      await transferService.sendFile(
        file: fileItem,
        target: DeviceModel(
          id: targetDeviceId,
          name: targetDeviceName,
          ipAddress: targetIp,
          port: targetPort,
          lastSeen: DateTime.now(),
        ),
        transferId: transferId,
        senderId: senderId,
        senderName: senderName,
        onProgress: (progress) {
          final updatedTransfer = transfer.copyWith(
            transferredBytes: progress.bytesTransferred,
            status: TransferStatus.inProgress.name,
          );
          _ref.read(transferHistoryProvider.notifier).updateTransfer(updatedTransfer);
          _ref.read(activeTransfersProvider.notifier).update(updatedTransfer);
        },
        onComplete: () {
          final completedTransfer = transfer.copyWith(
            transferredBytes: transfer.fileSizeBytes,
            status: TransferStatus.completed.name,
            completedAt: DateTime.now(),
          );
          _ref.read(transferHistoryProvider.notifier).updateTransfer(completedTransfer);
          _ref.read(activeTransfersProvider.notifier).remove(transferId);
          state = const AsyncValue.data(null);
        },
        onError: (error) {
          final failedTransfer = transfer.copyWith(
            status: TransferStatus.failed.name,
            completedAt: DateTime.now(),
          );
          _ref.read(transferHistoryProvider.notifier).updateTransfer(failedTransfer);
          _ref.read(activeTransfersProvider.notifier).remove(transferId);
          state = AsyncValue.error(error, StackTrace.current);
        },
        onRejected: () {
          final rejectedTransfer = transfer.copyWith(
            status: TransferStatus.rejected.name,
            completedAt: DateTime.now(),
          );
          _ref.read(transferHistoryProvider.notifier).updateTransfer(rejectedTransfer);
          _ref.read(activeTransfersProvider.notifier).remove(transferId);
          state = const AsyncValue.data(null);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
