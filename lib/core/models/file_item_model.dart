import 'dart:io';
import 'package:mime/mime.dart';

class FileItemModel {
  final String path;
  final String name;
  final int sizeBytes;
  final String mimeType;
  final String extension;

  const FileItemModel({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.extension,
  });

  static Future<FileItemModel> fromPath(String path) async {
    final file = File(path);
    final stat = await file.stat();
    final name = path.split('/').last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final mime = lookupMimeType(path) ?? 'application/octet-stream';

    return FileItemModel(
      path: path,
      name: name,
      sizeBytes: stat.size,
      mimeType: mime,
      extension: ext,
    );
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '${sizeBytes}B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isDocument =>
      mimeType.startsWith('application/') || mimeType.startsWith('text/');
}
