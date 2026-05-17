import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';

class IncomingTransferHeader {
  final String transferId;
  final String fileName;
  final int fileSizeBytes;
  final String senderId;
  final String senderName;

  IncomingTransferHeader({
    required this.transferId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.senderId,
    required this.senderName,
  });

  factory IncomingTransferHeader.fromJson(Map<String, dynamic> json) {
    return IncomingTransferHeader(
      transferId: json['transferId'] as String,
      fileName: json['fileName'] as String,
      fileSizeBytes: json['fileSizeBytes'] as int,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
    );
  }
}

class TransferProgress {
  final int bytesReceived;
  final int totalBytes;

  TransferProgress(this.bytesReceived, this.totalBytes);
}

class SocketServer {
  ServerSocket? _serverSocket;
  final Map<String, _PendingTransfer> _pendingTransfers = {};
  final StreamController<IncomingTransferHeader> _headerController =
      StreamController<IncomingTransferHeader>.broadcast();
  final Map<String, StreamController<TransferProgress>> _progressControllers = {};

  Stream<IncomingTransferHeader> get onIncomingTransfer => _headerController.stream;

  Future<int> start() async {
    if (_serverSocket != null) return _serverSocket!.port;
    _serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _serverSocket!.listen(_handleConnection);
    return _serverSocket!.port;
  }

  void _handleConnection(Socket socket) {
    socket.listen((data) {
      String message = utf8.decode(data);
      if (message.contains('\n')) {
        final parts = message.split('\n');
        final headerJson = parts.first;
        try {
          final json = jsonDecode(headerJson);
          final header = IncomingTransferHeader.fromJson(json);
          _pendingTransfers[header.transferId] = _PendingTransfer(socket: socket, header: header);
          _headerController.add(header);

          // Notify background service
          FlutterBackgroundService().invoke('incoming_request', {
            'id': header.transferId,
            'fileName': header.fileName,
            'peerName': header.senderName,
            'fileSize': '${(header.fileSizeBytes / 1024 / 1024).toStringAsFixed(1)}MB',
          });
        } catch (e) {
          socket.close();
        }
      }
    });
  }

  Future<void> acceptTransfer(String transferId, String savePath) async {
    final pending = _pendingTransfers[transferId];
    if (pending == null) throw Exception('Transfer not found');
    final socket = pending.socket;
    final header = pending.header;

    // Send accept byte (0x01)
    socket.add([0x01]);
    await socket.flush();

    // Receive file data
    final file = File(savePath);
    final ios = file.openSync(mode: FileMode.write);
    int received = 0;
    final progressController = StreamController<TransferProgress>.broadcast();
    _progressControllers[transferId] = progressController;

    socket.listen(
      (bytes) {
        ios.writeFromSync(bytes);
        received += bytes.length;
        progressController.add(TransferProgress(received, header.fileSizeBytes));
        if (received >= header.fileSizeBytes) {
          ios.closeSync();
          socket.close();
          progressController.close();
          _progressControllers.remove(transferId);
          _pendingTransfers.remove(transferId);
        }
      },
      onError: (e) {
        ios.closeSync();
        socket.close();
        progressController.addError(e);
        progressController.close();
        _progressControllers.remove(transferId);
        _pendingTransfers.remove(transferId);
      },
    );
  }

  void rejectTransfer(String transferId) {
    final pending = _pendingTransfers[transferId];
    if (pending != null) {
      pending.socket.add([0x00]);
      pending.socket.flush();
      pending.socket.close();
      _pendingTransfers.remove(transferId);
    }
  }

  Stream<TransferProgress> getProgressStream(String transferId) {
    return _progressControllers[transferId]?.stream ?? const Stream.empty();
  }

  Future<void> stop() async {
    await _serverSocket?.close();
    for (var controller in _progressControllers.values) {
      await controller.close();
    }
    _progressControllers.clear();
    _pendingTransfers.clear();
    await _headerController.close();
  }
}

class _PendingTransfer {
  final Socket socket;
  final IncomingTransferHeader header;
  _PendingTransfer({required this.socket, required this.header});
}
