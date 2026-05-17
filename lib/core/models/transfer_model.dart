class TransferModel {
  final String id;
  final String fileName;
  final int fileSizeBytes;
  final int transferredBytes;
  final String status; // stored as string
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

  // Keep enums and status helpers for logic
  // (Assuming TransferStatus/Direction are defined elsewhere or added here if needed)
  
  double get progressFraction {
    if (fileSizeBytes == 0) return 0.0;
    return (transferredBytes / fileSizeBytes).clamp(0.0, 1.0);
  }

  String get formattedSize {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
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

  factory TransferModel.fromJson(Map<String, dynamic> json) => TransferModel(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        fileSizeBytes: json['fileSizeBytes'] as int,
        transferredBytes: json['transferredBytes'] as int? ?? 0,
        status: json['status'] as String,
        direction: json['direction'] as String,
        peerId: json['peerId'] as String,
        peerName: json['peerName'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        localPath: json['localPath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'fileSizeBytes': fileSizeBytes,
        'transferredBytes': transferredBytes,
        'status': status,
        'direction': direction,
        'peerId': peerId,
        'peerName': peerName,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'localPath': localPath,
      };
}
