import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/models/transfer_model.dart';
import '../../shared/widgets/glassmorphic_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(transferHistoryProvider);
    final successful = history.where((t) => t.transferStatus == TransferStatus.completed).length;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'echoSystem',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: EchoColors.icyWhite,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Premium LAN File Sharing',
            style: TextStyle(fontSize: 18, color: EchoColors.pewter),
          ),
          const SizedBox(height: 40),
          GlassmorphicCard(
            title: 'Dashboard',
            content: 'Total Transfers: ${history.length}\nSuccessful: $successful\n\nTap the Devices tab to start sharing!',
          ),
        ],
      ),
    );
  }
}
