import 'package:hive/hive.dart';

part 'transfer_model.g.dart';

enum TransferStatus { pending, inProgress, completed, failed, rejected }
enum TransferDirection { sending, receiving }

@HiveType(typeId: 1)
class TransferModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fileName;

  @HiveField(2)
  final int fileSizeBytes;

  @HiveField(3)
  final int transferredBytes;

  @HiveField(4)
  final String status; // stored as string for Hive compatibility

  @HiveField(5)
  final String direction;

  @HiveField(6)
  final String peerId;

  @HiveField(7)
  final String peerName;

  @HiveField(8)
  final DateTime startedAt;

  @HiveField(9)
  final DateTime? completedAt;

  @HiveField(10)
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
      TransferStatus.values.firstWhere((e) => e.name == status,
          orElse: () => TransferStatus.pending);

  TransferDirection get transferDirection =>
      TransferDirection.values.firstWhere((e) => e.name == direction,
          orElse: () => TransferDirection.sending);

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
