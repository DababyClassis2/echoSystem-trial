import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/transfer_model.dart';
import '../../core/providers/providers.dart';
import 'export_service.dart';

class ActiveTransferPage extends ConsumerWidget {
  const ActiveTransferPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfers = ref.watch(activeTransfersProvider);
    final historyAsync = ref.watch(transferHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Transfers'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              final transfers = historyAsync.value ?? [];
              if (v == 'csv') await TransferExportService.share(transfers);
              if (v == 'text') await TransferExportService.shareText(transfers);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              const PopupMenuItem(value: 'text', child: Text('Share as text')),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: transfers.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                  size: 64, color: Colors.greenAccent),
                SizedBox(height: 12),
                Text('All transfers complete',
                  style: TextStyle(color: Colors.white70)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: transfers.length,
            itemBuilder: (_, i) => _TransferProgressCard(
              transfer: transfers[i],
            ),
          ),
    );
  }
}

class _TransferProgressCard extends ConsumerWidget {
  final TransferModel transfer;
  const _TransferProgressCard({required this.transfer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncoming = transfer.transferDirection == TransferDirection.receiving;
    final accent     = isIncoming ? Colors.purpleAccent : Colors.blueAccent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.15),
                child: Icon(
                  isIncoming ? Icons.download_rounded : Icons.upload_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transfer.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    '${isIncoming ? "From" : "To"}: ${transfer.peerName}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              )),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                onPressed: () => _confirmCancel(context, ref),
                tooltip: 'Cancel transfer',
              ),
            ]),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: transfer.progress),
                duration: const Duration(milliseconds: 300),
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: accent.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(transfer.progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${_fmt(transfer.transferredBytes)} / ${_fmt(transfer.fileSizeBytes)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Row(children: [
                  const Icon(Icons.speed, size: 13, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    '${_fmtSpeed(transfer.speedBytesPerSec)} · ETA ${transfer.eta}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _fmtSpeed(double? bps) {
    if (bps == null || bps <= 0) return '—';
    if (bps < 1024) return '${bps.toStringAsFixed(0)}B/s';
    if (bps < 1024 * 1024) return '${(bps / 1024).toStringAsFixed(1)}KB/s';
    return '${(bps / (1024 * 1024)).toStringAsFixed(1)}MB/s';
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel transfer?'),
        content: Text('Cancel "${transfer.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep going'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              ref.read(activeTransfersProvider.notifier).remove(transfer.id);
            },
            child: const Text('Cancel transfer'),
          ),
        ],
      ),
    );
  }
}
