import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/socket_server.dart';

class IncomingDialog extends ConsumerStatefulWidget {
  final IncomingTransferHeader header;
  const IncomingDialog({super.key, required this.header});

  @override
  ConsumerState<IncomingDialog> createState() => _IncomingDialogState();
}

class _IncomingDialogState extends ConsumerState<IncomingDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Incoming File'),
      content: Text('From: ${widget.header.senderName}\nFile: ${widget.header.fileName}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Reject')),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Accept')),
      ],
    );
  }
}

// Helper function to show the dialog
Future<void> showIncomingDialog(BuildContext context, IncomingTransferHeader header) {
  return showDialog(
    context: context,
    builder: (context) => IncomingDialog(header: header),
  );
}
