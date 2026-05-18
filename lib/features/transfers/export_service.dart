import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../../core/models/transfer_model.dart';

class TransferExportService {
  static String toCsv(List<TransferModel> transfers) {
    final sb = StringBuffer();
    sb.writeln('ID,File,Peer,Direction,Status,Size (bytes),Speed (B/s),Started,Completed');
    for (final t in transfers) {
      final line = [
        t.id,
        t.fileName,
        t.peerName,
        t.direction?.name ?? 'unknown',
        t.status,
        t.fileSizeBytes,
        t.speedBytesPerSec?.toStringAsFixed(0) ?? '',
        t.startedAt?.toIso8601String() ?? '',
        t.completedAt?.toIso8601String() ?? '',
      ].join(',');
      sb.writeln(line);
    }
    return sb.toString();
  }

  static Future<String> saveCsv(List<TransferModel> transfers) async {
    final csv  = toCsv(transfers);
    final dir  = Directory('/storage/emulated/0/Download');
    final name = 'echosystem_history_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$name');
    await file.writeAsString(csv);
    return file.path;
  }

  static Future<void> share(List<TransferModel> transfers) async {
    final path = await saveCsv(transfers);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'text/csv')],
      subject: 'echoSystem transfer history',
    );
  }

  static Future<void> shareText(List<TransferModel> transfers) async {
    final sb = StringBuffer('echoSystem Transfer History\n');
    sb.writeln('Exported: ${DateTime.now()}\n');
    for (final t in transfers.take(50)) {
      sb.writeln('${t.fileName} → ${t.peerName} [${t.status}] ${t.startedAt}');
    }
    await Share.share(sb.toString(), subject: 'Transfer History');
  }
}
