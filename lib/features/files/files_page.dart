import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/transfer_model.dart';
import '../../core/providers/providers.dart';
import '../../app/theme.dart';
import 'files_controller.dart';

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
    // Load history into provider (if not already loaded)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transferHistoryProvider.notifier).loadFromStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(transferHistoryProvider);
    final controller = ref.watch(filesControllerProvider);

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
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearAllDialog(context, controller),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
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
                ? const Center(
                    child: Text(
                      'No transfers yet.\nShare files from the Devices tab.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: EchoColors.pewter),
                    ),
                  )
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
                              ...entry.value.map((t) => _TransferTile(
                                    transfer: t,
                                    onTap: () => _openFile(t, controller),
                                    onDelete: () => _deleteTransfer(t.id, controller),
                                  )),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
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
      backgroundColor: EchoColors.chromeBlueGrey.withOpacity(0.3),
      selectedColor: EchoColors.warmGold.withOpacity(0.3),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
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
    } else {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transfer record deleted')),
              );
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
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TransferTile({required this.transfer, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    switch (transfer.transferStatus) {
      case TransferStatus.completed:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case TransferStatus.failed:
        icon = Icons.error;
        iconColor = Colors.red;
        break;
      case TransferStatus.rejected:
        icon = Icons.block;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.pending;
        iconColor = EchoColors.warmGold;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(transfer.transferDirection == TransferDirection.sending ? Icons.arrow_upward : Icons.arrow_downward, color: EchoColors.warmGold),
        title: Text(transfer.fileName, style: const TextStyle(color: EchoColors.icyWhite)),
        subtitle: Text(
          '${transfer.formattedSize} • ${transfer.peerName} • ${_formatDate(transfer.startedAt)}',
          style: const TextStyle(color: EchoColors.pewter, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: EchoColors.pewter),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

enum TransferFilter { all, sent, received, failed }
