import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/models/transfer_model.dart';
import '../../shared/widgets/glassmorphic_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(transferHistoryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(transferHistoryProvider.notifier).loadFromStorage();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Column(
              children: [
                Text(
                  'echoSystem',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: EchoColors.icyWhite,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Premium LAN File Sharing',
                  style: TextStyle(fontSize: 16, color: EchoColors.pewter),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Quick Stats Row
          historyAsync.when(
            loading: () => _buildStatsShimmer(),
            error: (e, _) => _buildStatsError(e),
            data: (transfers) => _buildStatsRow(transfers),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Actions Row
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  label: 'Scan for Devices',
                  icon: Icons.search,
                  onPressed: () => context.go('/devices'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  label: 'View Files',
                  icon: Icons.folder_open,
                  onPressed: () => context.go('/files'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Recent Transfers
          _SectionHeader('Recent Transfers'),
          const SizedBox(height: 12),
          historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error loading history', style: TextStyle(color: Colors.redAccent)),
            data: (history) {
              if (history.isEmpty) {
                return const GlassmorphicCard(
                  title: 'No recent transfers',
                  content: 'Sent files will appear here.',
                );
              }
              return Column(
                children: history.reversed.take(3).map((t) => _RecentTransferTile(transfer: t)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<TransferModel> transfers) {
    final completed = transfers.where((t) => t.transferStatus == TransferStatus.completed).length;
    final failed = transfers.where((t) => t.transferStatus == TransferStatus.failed).length;
    final total = transfers.length;

    return Row(
      children: [
        _StatCard(title: 'Total', count: total, icon: Icons.history, index: 0),
        const SizedBox(width: 12),
        _StatCard(title: 'Done', count: completed, icon: Icons.check_circle_outline, color: Colors.greenAccent, index: 1),
        const SizedBox(width: 12),
        _StatCard(title: 'Failed', count: failed, icon: Icons.error_outline, color: Colors.redAccent, index: 2),
      ],
    );
  }

  Widget _buildStatsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.1),
      highlightColor: Colors.white.withValues(alpha: 0.2),
      child: Row(
        children: [
          _StatCard(title: '—', count: 0, icon: Icons.sync, index: 0, isPlaceholder: true),
          const SizedBox(width: 12),
          _StatCard(title: '—', count: 0, icon: Icons.sync, index: 1, isPlaceholder: true),
          const SizedBox(width: 12),
          _StatCard(title: '—', count: 0, icon: Icons.sync, index: 2, isPlaceholder: true),
        ],
      ),
    );
  }

  Widget _buildStatsError(Object error) {
    return Center(
      child: Text(
        'Error: $error',
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color? color;
  final int index;
  final bool isPlaceholder;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    this.color,
    required this.index,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + (index * 100)),
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color ?? EchoColors.warmGold, size: 24),
              const SizedBox(height: 8),
              if (isPlaceholder)
                const Text('—', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))
              else
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: count),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, _) => Text(
                    '$value',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              Text(title, style: const TextStyle(color: EchoColors.pewter, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _QuickActionButton({required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: EchoColors.warmGold,
        foregroundColor: EchoColors.deepNavy,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(color: EchoColors.warmGold, fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _RecentTransferTile extends StatelessWidget {
  final TransferModel transfer;
  const _RecentTransferTile({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = transfer.transferStatus == TransferStatus.completed;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.error,
          color: isCompleted ? Colors.greenAccent : Colors.redAccent,
        ),
        title: Text(
          transfer.fileName,
          style: const TextStyle(color: EchoColors.icyWhite, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${transfer.peerName} • ${transfer.status}',
          style: const TextStyle(color: EchoColors.pewter, fontSize: 12),
        ),
        trailing: Text(
          _formatTime(transfer.startedAt),
          style: const TextStyle(color: EchoColors.pewter, fontSize: 10),
        ),
      ),
    );
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
