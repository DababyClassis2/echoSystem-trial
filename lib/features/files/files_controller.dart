import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import '../../core/models/transfer_model.dart';
import '../../core/providers/providers.dart';

final filesControllerProvider = Provider<FilesController>((ref) {
  return FilesController(ref);
});

class FilesController {
  final Ref _ref;
  FilesController(this._ref);

  List<TransferModel> getHistory() {
    return _ref.read(transferHistoryProvider);
  }

  Future<void> deleteTransfer(String id) async {
    await _ref.read(transferHistoryProvider.notifier).deleteTransfer(id);
  }

  Future<void> clearAllHistory() async {
    await _ref.read(transferHistoryProvider.notifier).clearAll();
  }

  Future<void> openFile(String path) async {
    if (path.isEmpty) return;
    final result = await OpenFile.open(path);
    if (result.type != ResultType.done) {
      // Could show error, but ignore for now
    }
  }

  // Group transfers by date
  Map<String, List<TransferModel>> groupByDate(List<TransferModel> transfers) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<TransferModel>> groups = {
      'Today': [],
      'Yesterday': [],
      'Older': [],
    };

    for (final t in transfers) {
      final date = DateTime(t.startedAt.year, t.startedAt.month, t.startedAt.day);
      if (date == today) {
        groups['Today']!.add(t);
      } else if (date == yesterday) {
        groups['Yesterday']!.add(t);
      } else {
        groups['Older']!.add(t);
      }
    }
    // Remove empty groups
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }
}
