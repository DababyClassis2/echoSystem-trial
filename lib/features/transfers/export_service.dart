import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../core/models/transfer_model.dart';

class TransferExportService {
  /// Generates a CSV string from transfer history
  static String toCsv(List<TransferModel> transfers) {
    final rows = [
      // Header row
      ['ID','File','Peer','Direction','Status','Size (bytes)',
       'Speed (B/s)','Started','Completed'],
      // Data rows
      ...transfers.map((t) => [
        t.id,
        t.fileName,
        t.peerName,
        t.direction ?? 'unknown',
        t.status,
        t.fileSize?.toString() ?? '',
        t.speedBytesPerSec?.toStringAsFixed(0) ?? '',
        t.startedAt?.toIso8601String() ?? '',
        t.completedAt?.toIso8601String() ?? '',
      ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  /// Saves CSV to Downloads and returns the file path
  static Future<String> saveCsv(List<TransferModel> transfers) async {
    final csv  = toCsv(transfers);
    final dir  = Directory('/storage/emulated/0/Download');
    final name = 'echosystem_history_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$name');
    await file.writeAsString(csv);
    return file.path;
  }

  /// Opens the system share sheet with the CSV
  static Future<void> share(List<TransferModel> transfers) async {
    final path = await saveCsv(transfers);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'text/csv')],
      subject: 'echoSystem transfer history',
    );
  }

  /// Share as plain text summary
  static Future<void> shareText(List<TransferModel> transfers) async {
    final sb = StringBuffer('echoSystem Transfer History\n');
    sb.writeln('Exported: ${DateTime.now()}\n');
    for (final t in transfers.take(50)) {
      sb.writeln('${t.fileName} → ${t.peerName} [${t.status}] ${t.startedAt}');
    }
    await Share.share(sb.toString(), subject: 'Transfer History');
  }
}
