import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/models/transfer_model.dart';
import '../../core/providers/providers.dart';
import '../../app/theme.dart';

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  @override
  void initState() {
    super.initState();
    // Ensure history is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transferHistoryProvider.notifier).loadFromStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(transferHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          if (history.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _exportLogs(history),
              tooltip: 'Export logs',
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearAllDialog(context),
              tooltip: 'Clear all logs',
            ),
          ],
        ],
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                'No logs yet.\nTransfers will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: EchoColors.pewter),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final transfer = history[index];
                return _LogEntry(transfer: transfer);
              },
            ),
    );
  }

  Future<void> _exportLogs(List<TransferModel> history) async {
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) throw Exception('No downloads directory');
      final file = File('${directory.path}/echosystem_logs_${DateTime.now().millisecondsSinceEpoch}.txt');
      final buffer = StringBuffer();
      buffer.writeln('echoSystem Transfer Logs');
      buffer.writeln('Generated: ${DateTime.now()}');
      buffer.writeln('=' * 50);
      buffer.writeln();

      for (final t in history) {
        buffer.writeln('ID: ${t.id}');
        buffer.writeln('File: ${t.fileName}');
        buffer.writeln('Size: ${t.formattedSize}');
        buffer.writeln('Direction: ${t.direction.toUpperCase()}');
        buffer.writeln('Status: ${t.status.toUpperCase()}');
        buffer.writeln('Peer: ${t.peerName} (${t.peerId})');
        buffer.writeln('Started: ${t.startedAt}');
        if (t.completedAt != null) buffer.writeln('Completed: ${t.completedAt}');
        if (t.transferDuration != null) buffer.writeln('Duration: ${t.transferDuration!.inSeconds} seconds');
        buffer.writeln('-' * 50);
      }

      await file.writeAsString(buffer.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logs saved to ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EchoColors.navySlate,
        title: const Text('Clear All Logs?', style: TextStyle(color: EchoColors.icyWhite)),
        content: const Text('This will permanently delete all transfer history.', style: TextStyle(color: EchoColors.pewter)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: EchoColors.warmGold)),
          ),
          TextButton(
            onPressed: () {
              ref.read(transferHistoryProvider.notifier).clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All logs cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final TransferModel transfer;
  const _LogEntry({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final isSending = transfer.transferDirection == TransferDirection.sending;
    final isCompleted = transfer.transferStatus == TransferStatus.completed;
    final isFailed = transfer.transferStatus == TransferStatus.failed;
    final isRejected = transfer.transferStatus == TransferStatus.rejected;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'COMPLETED';
    } else if (isFailed) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'FAILED';
    } else if (isRejected) {
      statusColor = Colors.orange;
      statusIcon = Icons.block;
      statusText = 'REJECTED';
    } else {
      statusColor = EchoColors.warmGold;
      statusIcon = Icons.pending;
      statusText = 'PENDING';
    }

    final directionIcon = isSending ? Icons.arrow_upward : Icons.arrow_downward;
    final directionText = isSending ? 'SENT' : 'RECEIVED';
    final speedInfo = isCompleted && transfer.transferDuration != null && transfer.transferDuration!.inSeconds > 0
        ? ' • ${(transfer.fileSizeBytes / transfer.transferDuration!.inSeconds).round()} B/s'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 16),
                const SizedBox(width: 6),
                Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(directionIcon, color: EchoColors.warmGold, size: 16),
                const SizedBox(width: 4),
                Text(directionText, style: const TextStyle(color: EchoColors.warmGold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(transfer.fileName, style: const TextStyle(color: EchoColors.icyWhite, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              '${transfer.formattedSize} • ${transfer.peerName} • ${_formatDate(transfer.startedAt)}${speedInfo}',
              style: const TextStyle(color: EchoColors.pewter, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
