import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/transfer_model.dart';
import '../../core/providers/providers.dart';
import '../../app/theme.dart';
import 'files_controller.dart';
import '../transfers/export_service.dart';

class FilesPage extends ConsumerStatefulWidget {
  const FilesPage({super.key});

  @override
  ConsumerState<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends ConsumerState<FilesPage> {
  TransferFilter _filter = TransferFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(transferHistoryProvider.notifier).loadFromStorage();
      }
    });
  }

  ({Color color, IconData icon, String label}) _statusMeta(String status) {
    return switch (status.toLowerCase()) {
      'completed'  => (color: Colors.greenAccent,  icon: Icons.check_circle_outline,   label: 'Done'),
      'failed'     => (color: Colors.redAccent,     icon: Icons.error_outline,           label: 'Failed'),
      'cancelled'  => (color: Colors.orangeAccent,  icon: Icons.cancel_outlined,         label: 'Cancelled'),
      'sending'    => (color: Colors.blueAccent,    icon: Icons.upload_rounded,          label: 'Sending'),
      'receiving'  => (color: Colors.purpleAccent,  icon: Icons.download_rounded,        label: 'Receiving'),
      _            => (color: Colors.white54,       icon: Icons.hourglass_empty_rounded, label: status),
    };
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(transferHistoryProvider);
    final controller = ref.watch(filesControllerProvider);

    return historyAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, st) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (history) {
        final filtered = history.where((t) {
          switch (_filter) {
            case TransferFilter.sent:
              return t.transferDirection == TransferDirection.sending;
            case TransferFilter.received:
              return t.transferDirection == TransferDirection.receiving;
            case TransferFilter.failed:
              return t.transferStatus == TransferStatus.failed;
            default:
              return true;
          }
        }).toList();

        final groups = controller.groupByDate(filtered);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Files'),
            actions: [
              if (history.isNotEmpty)
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    final transfers = ref.read(transferHistoryProvider).value ?? [];
                    if (v == 'csv') await TransferExportService.share(transfers);
                    if (v == 'text') await TransferExportService.shareText(transfers);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'csv',  child: Text('Export CSV')),
                    const PopupMenuItem(value: 'text', child: Text('Share as text')),
                  ],
                  icon: const Icon(Icons.share),
                ),
              if (history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _showClearAllDialog(context, controller),
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('All', TransferFilter.all),
                    const SizedBox(width: 8),
                    _buildFilterChip('Sent', TransferFilter.sent),
                    const SizedBox(width: 8),
                    _buildFilterChip('Received', TransferFilter.received),
                    const SizedBox(width: 8),
                    _buildFilterChip('Failed', TransferFilter.failed),
                  ],
                ),
              ),
              Expanded(
                child: history.isEmpty
                    ? _buildEmptyState(context)
                    : groups.isEmpty
                        ? const Center(
                            child: Text(
                              'No transfers match the filter.',
                              style: TextStyle(color: EchoColors.pewter),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: groups.entries.map((entry) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      color: EchoColors.warmGold,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...entry.value.map((t) {
                                    final meta = _statusMeta(t.status);
                                    return _TransferTile(
                                      transfer: t,
                                      meta: meta,
                                      onTap: () => _openFile(t, controller),
                                      onDelete: () => _deleteTransfer(t.id, controller),
                                    );
                                  }),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }).toList(),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.swap_horiz_rounded, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No transfers yet', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => context.go('/devices'),
            icon: const Icon(Icons.radar),
            label: const Text('Scan for Devices'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EchoColors.warmGold,
              foregroundColor: EchoColors.deepNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TransferFilter filter) {
    return FilterChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (selected) {
        setState(() {
          _filter = filter;
        });
      },
      backgroundColor: EchoColors.chromeBlueGrey.withValues(alpha: 0.3),
      selectedColor: EchoColors.warmGold.withValues(alpha: 0.3),
      labelStyle: TextStyle(
        color: _filter == filter ? EchoColors.warmGold : EchoColors.icyWhite,
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, FilesController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EchoColors.navySlate,
        title: const Text('Clear All History?', style: TextStyle(color: EchoColors.icyWhite)),
        content: const Text('This action cannot be undone.', style: TextStyle(color: EchoColors.pewter)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: EchoColors.warmGold)),
          ),
          TextButton(
            onPressed: () {
              controller.clearAllHistory();
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _openFile(TransferModel transfer, FilesController controller) {
    if (transfer.localPath != null && transfer.localPath!.isNotEmpty) {
      controller.openFile(transfer.localPath!);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not available locally')),
      );
    }
  }

  void _deleteTransfer(String id, FilesController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EchoColors.navySlate,
        title: const Text('Delete Transfer Record?', style: TextStyle(color: EchoColors.icyWhite)),
        content: const Text('The file will remain on your device, but this record will be removed from the history.', style: TextStyle(color: EchoColors.pewter)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: EchoColors.warmGold)),
          ),
          TextButton(
            onPressed: () {
              controller.deleteTransfer(id);
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transfer record deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  final TransferModel transfer;
  final ({Color color, IconData icon, String label}) meta;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TransferTile({
    required this.transfer,
    required this.meta,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        onLongPress: onDelete,
        leading: CircleAvatar(
          backgroundColor: meta.color.withValues(alpha: 0.15),
          child: Icon(meta.icon, color: meta.color, size: 20),
        ),
        title: Text(
          transfer.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, color: EchoColors.icyWhite),
        ),
        subtitle: Text(
          '${transfer.peerName} • ${_formatTime(transfer.startedAt)}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: meta.color.withValues(alpha: 0.4)),
              ),
              child: Text(
                meta.label,
                style: TextStyle(color: meta.color, fontSize: 11),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatSize(transfer.fileSizeBytes),
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

enum TransferFilter { all, sent, received, failed }
