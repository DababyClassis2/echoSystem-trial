enum TransferStatus { pending, inProgress, completed, failed, rejected }
enum TransferDirection { sending, receiving }

class TransferModel {
  final String id;
  final String fileName;
  final int fileSizeBytes;
  final int transferredBytes;
  final String status;
  final String direction;
  final String peerId;
  final String peerName;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? localPath;

  const TransferModel({
    required this.id,
    required this.fileName,
    required this.fileSizeBytes,
    this.transferredBytes = 0,
    required this.status,
    required this.direction,
    required this.peerId,
    required this.peerName,
    required this.startedAt,
    this.completedAt,
    this.localPath,
  });

  TransferStatus get transferStatus =>
      TransferStatus.values.firstWhere((e) => e.name == status, orElse: () => TransferStatus.pending);

  TransferDirection get transferDirection =>
      TransferDirection.values.firstWhere((e) => e.name == direction, orElse: () => TransferDirection.sending);

  double get progressFraction {
    if (fileSizeBytes == 0) return 0.0;
    return (transferredBytes / fileSizeBytes).clamp(0.0, 1.0);
  }

  String get formattedSize {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    if (fileSizeBytes < 1024 * 1024 * 1024) return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  Duration? get transferDuration {
    if (completedAt == null) return null;
    return completedAt!.difference(startedAt);
  }

  TransferModel copyWith({
    String? id,
    String? fileName,
    int? fileSizeBytes,
    int? transferredBytes,
    String? status,
    String? direction,
    String? peerId,
    String? peerName,
    DateTime? startedAt,
    DateTime? completedAt,
    String? localPath,
  }) {
    return TransferModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      status: status ?? this.status,
      direction: direction ?? this.direction,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      localPath: localPath ?? this.localPath,
    );
  }
}
