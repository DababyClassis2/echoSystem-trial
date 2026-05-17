import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../models/file_item_model.dart';

class TransferRejectedException implements Exception {
  final String message;
  TransferRejectedException(this.message);
  @override
  String toString() => message;
}

class TransferProgress {
  final int bytesTransferred;
  final int totalBytes;
  final double bytesPerSecond;

  TransferProgress(this.bytesTransferred, this.totalBytes, this.bytesPerSecond);

  double get fraction => bytesTransferred / totalBytes;
}

class TransferService {
  static const int CHUNK_SIZE = 64 * 1024; // 64KB
  static const int ACK_TIMEOUT_SECONDS = 30;
  static const int MAX_RETRIES = 3;

  StreamController<TransferProgress>? _progressController;
  Socket? _socket;
  bool _cancelled = false;

  Future<void> sendFile({
    required FileItemModel file,
    required DeviceModel target,
    required String transferId,
    required String senderId,
    required String senderName,
    required void Function(TransferProgress progress) onProgress,
    required void Function() onComplete,
    required void Function(Object error) onError,
    VoidCallback? onRejected,
  }) async {
    _progressController = StreamController<TransferProgress>.broadcast();
    _progressController!.stream.listen(onProgress);

    int attempt = 0;
    while (attempt < MAX_RETRIES && !_cancelled) {
      attempt++;
      try {
        await _attemptSend(
          file: file,
          target: target,
          transferId: transferId,
          senderId: senderId,
          senderName: senderName,
          onRejected: onRejected,
        );
        onComplete();
        return;
      } on TransferRejectedException {
        rethrow;
      } on SocketException catch (e) {
        if (attempt >= MAX_RETRIES) {
          onError(e);
          return;
        }
        await Future.delayed(Duration(seconds: attempt * 2)); // exponential backoff
      } catch (e) {
        onError(e);
        return;
      }
    }
  }

  Future<void> _attemptSend({
    required FileItemModel file,
    required DeviceModel target,
    required String transferId,
    required String senderId,
    required String senderName,
    VoidCallback? onRejected,
  }) async {
    _socket = await Socket.connect(target.ipAddress, target.port, timeout: Duration(seconds: 10));
    final header = {
      'transferId': transferId,
      'fileName': file.name,
      'fileSizeBytes': file.sizeBytes,
      'senderId': senderId,
      'senderName': senderName,
    };
    final headerStr = jsonEncode(header) + '\n';
    _socket!.add(utf8.encode(headerStr));
    await _socket!.flush();

    // Wait for accept/reject byte with timeout
    final completer = Completer<int>();
    late StreamSubscription sub;
    sub = _socket!.listen(
      (data) {
        if (data.isNotEmpty) {
          completer.complete(data[0]);
          sub.cancel();
        }
      },
      onError: completer.completeError,
    );
    final result = await completer.future.timeout(Duration(seconds: ACK_TIMEOUT_SECONDS));
    if (result == 0x00) {
      _socket!.close();
      if (onRejected != null) onRejected();
      throw TransferRejectedException('Transfer rejected by peer');
    } else if (result != 0x01) {
      _socket!.close();
      throw Exception('Invalid response from peer');
    }

    // Send file in chunks with progress tracking
    final fileHandle = File(file.path).openSync();
    int sent = 0;
    final stopwatch = Stopwatch()..start();
    while (sent < file.sizeBytes && !_cancelled) {
      final chunk = fileHandle.readSync(CHUNK_SIZE);
      if (chunk.isEmpty) break;
      _socket!.add(chunk);
      await _socket!.flush();
      sent += chunk.length;
      final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
      final bytesPerSecond = elapsedSeconds > 0 ? sent / elapsedSeconds : 0;
      _progressController?.add(TransferProgress(sent, file.sizeBytes, bytesPerSecond.toDouble()));
    }
    stopwatch.stop();
    fileHandle.closeSync();
    await _socket!.close();
    _progressController?.close();
  }

  void cancel() {
    _cancelled = true;
    _socket?.close();
    _progressController?.close();
  }

  void dispose() {
    cancel();
  }
}
