import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum FileBrowserTab { all, images, videos, documents, apk }
enum ViewMode { list, grid }

class FileBrowserPage extends ConsumerStatefulWidget {
  const FileBrowserPage({super.key});
  @override
  ConsumerState<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends ConsumerState<FileBrowserPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  ViewMode _view = ViewMode.list;
  final Set<String> _selected = {};
  List<FileSystemEntity> _files = [];
  bool _loading = true;

  final _tabFilters = {
    FileBrowserTab.all: <String>[],
    FileBrowserTab.images: ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'],
    FileBrowserTab.videos: ['.mp4', '.mkv', '.avi', '.mov', '.3gp'],
    FileBrowserTab.documents: ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.txt', '.zip'],
    FileBrowserTab.apk: ['.apk'],
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _tabCtrl.addListener(() => _loadFiles());
    _loadFiles();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
      _selected.clear();
    });

    final externalDir = await getExternalStorageDirectory();
    final dirs = [
      if (externalDir != null) externalDir,
      Directory('/storage/emulated/0/Download'),
      Directory('/storage/emulated/0/DCIM'),
      Directory('/storage/emulated/0/Documents'),
    ].whereType<Directory>().toList();

    final extensions = _tabFilters[FileBrowserTab.values[_tabCtrl.index]]!;
    final all = <FileSystemEntity>[];

    for (final dir in dirs) {
      if (!await dir.exists()) continue;
      try {
        await for (final e in dir.list(recursive: true)) {
          if (e is! File) continue;
          final ext = p.extension(e.path).toLowerCase();
          if (extensions.isEmpty || extensions.contains(ext)) all.add(e);
        }
      } catch (e) {
        // Skip inaccessible directories
      }
    }

    all.sort((a, b) {
      final sa = (a as File).lastModifiedSync();
      final sb = (b as File).lastModifiedSync();
      return sb.compareTo(sa);
    });

    if (mounted) {
      setState(() {
        _files = all;
        _loading = false;
      });
    }
  }

  void _toggleSelect(String path) {
    setState(() {
      if (_selected.contains(path)) {
        _selected.remove(path);
      } else {
        _selected.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selected.isEmpty
            ? const Text('Files')
            : Text('${_selected.length} selected'),
        actions: [
          IconButton(
            icon: Icon(_view == ViewMode.list
                ? Icons.grid_view_rounded
                : Icons.list_rounded),
            onPressed: () => setState(() => _view =
                _view == ViewMode.list ? ViewMode.grid : ViewMode.list),
          ),
          if (_selected.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.deselect),
              onPressed: () => setState(() => _selected.clear()),
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Images'),
            Tab(text: 'Videos'),
            Tab(text: 'Docs'),
            Tab(text: 'APK'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? _buildEmpty()
              : _view == ViewMode.list
                  ? _buildList()
                  : _buildGrid(),
      bottomNavigationBar: _selected.isEmpty ? null : _buildSendBar(),
    );
  }

  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _files.length,
        itemBuilder: (_, i) {
          final file = _files[i] as File;
          final path = file.path;
          final name = p.basename(path);
          final ext = p.extension(path).toLowerCase();
          final size = file.lengthSync();
          final chosen = _selected.contains(path);

          return ListTile(
            leading: Stack(children: [
              CircleAvatar(
                backgroundColor: _extColor(ext).withValues(alpha: 0.15),
                child: Text(
                  ext.replaceFirst('.', '').toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      color: _extColor(ext),
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (chosen)
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.check, size: 10, color: Colors.white),
                  ),
                ),
            ]),
            title: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
            subtitle: Text(_fmt(size),
                style: const TextStyle(fontSize: 11, color: Colors.white54)),
            selected: chosen,
            selectedTileColor: Colors.blueAccent.withValues(alpha: 0.08),
            onTap: () => _toggleSelect(path),
            onLongPress: () => _toggleSelect(path),
          );
        },
      );

  Widget _buildGrid() => GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
        itemCount: _files.length,
        itemBuilder: (_, i) {
          final file = _files[i] as File;
          final path = file.path;
          final ext = p.extension(path).toLowerCase();
          final chosen = _selected.contains(path);
          final isImg = ['.jpg', '.jpeg', '.png', '.webp', '.heic'].contains(ext);

          return GestureDetector(
            onTap: () => _toggleSelect(path),
            child: Stack(fit: StackFit.expand, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isImg
                    ? Image.file(file, fit: BoxFit.cover)
                    : Container(
                        color: _extColor(ext).withValues(alpha: 0.12),
                        child: Center(
                            child: Text(
                          ext.replaceFirst('.', '').toUpperCase(),
                          style: TextStyle(
                              color: _extColor(ext), fontWeight: FontWeight.bold),
                        )),
                      ),
              ),
              if (chosen)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueAccent, width: 2),
                  ),
                  child: const Center(
                      child: Icon(Icons.check_circle,
                          color: Colors.white, size: 32)),
                ),
            ]),
          );
        },
      );

  Widget _buildSendBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: const Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Row(children: [
          Expanded(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_selected.length} file(s) selected',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(_totalSizeLabel(),
                  style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ],
          )),
          ElevatedButton.icon(
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('Send'),
            onPressed: () => context.push('/devices',
                extra: {'filePaths': _selected.toList()}),
          ),
        ]),
      );

  Widget _buildEmpty() => Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open_rounded, size: 64, color: Colors.white24),
          const SizedBox(height: 12),
          const Text('No files found', style: TextStyle(color: Colors.white54)),
        ],
      ));

  String _totalSizeLabel() {
    int total = 0;
    for (final path in _selected) {
      total += File(path).lengthSync();
    }
    return _fmt(total);
  }

  String _fmt(int b) {
    if (b < 1024) return '${b}B';
    if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)}KB';
    return '${(b / 1048576).toStringAsFixed(1)}MB';
  }

  Color _extColor(String ext) => switch (ext) {
        '.jpg' || '.jpeg' || '.png' || '.gif' || '.webp' => Colors.pinkAccent,
        '.mp4' || '.mkv' || '.avi' || '.mov' => Colors.deepPurpleAccent,
        '.pdf' => Colors.redAccent,
        '.doc' || '.docx' => Colors.blueAccent,
        '.xls' || '.xlsx' => Colors.greenAccent,
        '.zip' || '.rar' || '.7z' => Colors.orangeAccent,
        '.apk' => Colors.tealAccent,
        _ => Colors.white54,
      };
}
