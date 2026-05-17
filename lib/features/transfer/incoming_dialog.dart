import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/socket_server.dart';
import '../../core/models/transfer_model.dart';
import '../../core/providers/providers.dart';
import '../../app/theme.dart';

class IncomingDialog extends ConsumerStatefulWidget {
  final IncomingTransferHeader header;

  const IncomingDialog({super.key, required this.header});

  @override
  ConsumerState<IncomingDialog> createState() => _IncomingDialogState();
}

class _IncomingDialogState extends ConsumerState<IncomingDialog> {
  bool _isProcessing = false;
  double _progress = 0.0;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final storage = ref.read(storageServiceProvider);
    final socketServer = ref.read(socketServerProvider);

    return AlertDialog(
      backgroundColor: EchoColors.navySlate,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(_getFileIcon(), color: EchoColors.warmGold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Incoming File',
              style: const TextStyle(color: EchoColors.icyWhite),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('From: ${widget.header.senderName}', style: const TextStyle(color: EchoColors.icyWhite)),
          const SizedBox(height: 8),
          Text('File: ${widget.header.fileName}', style: const TextStyle(color: EchoColors.icyWhite)),
          const SizedBox(height: 4),
          Text('Size: ${_formatSize(widget.header.fileSizeBytes)}', style: const TextStyle(color: EchoColors.pewter)),
          if (_isProcessing && _progress > 0) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress, color: EchoColors.warmGold),
            const SizedBox(height: 8),
            Text('${(_progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: EchoColors.pewter)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ],
      ),
      actions: _isProcessing
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: EchoColors.warmGold)),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
              ),
              ElevatedButton(
                onPressed: () => _acceptTransfer(socketServer, storage),
                child: const Text('Accept'),
                style: ElevatedButton.styleFrom(backgroundColor: EchoColors.warmGold),
              ),
            ],
    );
  }

  Future<void> _acceptTransfer(SocketServer socketServer, StorageService storage) async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    final saveDir = storage.defaultSavePath;
    final savePath = '$saveDir/${widget.header.fileName}';

    try {
      // Start accepting transfer
      await socketServer.acceptTransfer(widget.header.transferId, savePath);

      // Listen to progress stream for this transfer
      final progressStream = socketServer.getProgressStream(widget.header.transferId);
      await for (final progress in progressStream) {
        setState(() {
          _progress = progress.bytesReceived / progress.totalBytes;
        });
        if (_progress >= 1.0) break;
      }

      // Save transfer record
      final transfer = TransferModel(
        id: widget.header.transferId,
        fileName: widget.header.fileName,
        fileSizeBytes: widget.header.fileSizeBytes,
        transferredBytes: widget.header.fileSizeBytes,
        status: TransferStatus.completed.name,
        direction: TransferDirection.receiving.name,
        peerId: widget.header.senderId,
        peerName: widget.header.senderName,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        localPath: savePath,
      );
      await ref.read(transferHistoryProvider.notifier).addTransfer(transfer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File received successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  IconData _getFileIcon() {
    final ext = widget.header.fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return Icons.image;
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) return Icons.video_library;
    if (['mp3', 'wav', 'aac', 'flac'].contains(ext)) return Icons.audiotrack;
    if (['pdf', 'doc', 'docx', 'txt'].contains(ext)) return Icons.description;
    return Icons.insert_drive_file;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Helper function to show the dialog from anywhere
Future<void> showIncomingDialog(BuildContext context, IncomingTransferHeader header) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => IncomingDialog(header: header),
  );
}
ontext) => IncomingDialog(header: header),
  );
}
