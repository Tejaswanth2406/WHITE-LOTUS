import 'dart:typed_data';

import 'local_media_store.dart';

LocalMediaStore createLocalMediaStore() => _MemoryMediaStore();

class _MemoryMediaStore implements LocalMediaStore {
  final Map<String, Uint8List> _screenshots = {};
  final Map<String, Uint8List> _managedFiles = {};
  final Map<String, DateTime> _managedModified = {};
  final Set<String> _managedFolders = {''};
  final Map<String, _MemoryTrashItem> _trash = {};

  @override
  Future<StoredScreenshot> addScreenshot({
    required String name,
    required Uint8List bytes,
  }) async {
    _screenshots[name] = bytes;
    return StoredScreenshot(name: name);
  }

  @override
  Future<StoredOfflineMap> addOfflineMap({
    required String name,
    required Stream<List<int>> bytes,
  }) {
    throw UnsupportedError(
      'Offline MBTiles maps require a desktop or mobile app build.',
    );
  }

  @override
  Future<List<StoredOfflineMap>> listOfflineMaps() async => const [];

  @override
  Future<List<StoredScreenshot>> listScreenshots() async => _screenshots.keys
      .map((name) => StoredScreenshot(name: name))
      .toList(growable: false);

  @override
  Future<Uint8List> readScreenshot(String name) async => _screenshots[name]!;

  @override
  Future<String?> offlineMapPath(String id) async => null;

  @override
  Future<void> removeOfflineMap(String id) async {}

  @override
  Future<void> removeScreenshot(String name) async {
    _screenshots.remove(name);
  }

  String _safeName(String name) {
    final safeName = name.trim();
    if (safeName.isEmpty ||
        safeName == '.' ||
        safeName == '..' ||
        safeName.endsWith('.') ||
        safeName.endsWith(' ') ||
        RegExp(r'[<>:"/\\|?*\x00-\x1F]').hasMatch(safeName) ||
        RegExp(
          r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\..*)?$',
          caseSensitive: false,
        ).hasMatch(safeName)) {
      throw FormatException('Choose a valid file or folder name.');
    }
    return safeName;
  }

  String _safePath(String value, {bool allowRoot = false}) {
    if (allowRoot && value.isEmpty) return '';
    if (value.isEmpty || value.startsWith('/') || value.contains('\\')) {
      throw FormatException('Invalid workspace path.');
    }
    final segments = value.split('/');
    if (segments.any(
      (segment) => segment.isEmpty || segment != _safeName(segment),
    )) {
      throw FormatException('Invalid workspace path.');
    }
    return segments.join('/');
  }

  String _parentOf(String value) {
    final separator = value.lastIndexOf('/');
    return separator < 0 ? '' : value.substring(0, separator);
  }

  String _baseName(String value) {
    final separator = value.lastIndexOf('/');
    return separator < 0 ? value : value.substring(separator + 1);
  }

  @override
  Future<List<StoredManagedFile>> listManagedFiles({String folder = ''}) async {
    final safeFolder = _safePath(folder, allowRoot: true);
    if (!_managedFolders.contains(safeFolder)) {
      throw FormatException('This folder no longer exists.');
    }
    final prefix = safeFolder.isEmpty ? '' : '$safeFolder/';
    final entries = <StoredManagedFile>[];
    for (final path in _managedFolders) {
      if (path.isEmpty || path == safeFolder || !path.startsWith(prefix)) {
        continue;
      }
      final remainder = path.substring(prefix.length);
      if (!remainder.contains('/')) {
        entries.add(
          StoredManagedFile(
            path: path,
            name: remainder,
            isDirectory: true,
            size: 0,
            modified: DateTime.now(),
          ),
        );
      }
    }
    for (final path in _managedFiles.keys) {
      if (!path.startsWith(prefix)) continue;
      final remainder = path.substring(prefix.length);
      if (!remainder.contains('/')) {
        entries.add(
          StoredManagedFile(
            path: path,
            name: remainder,
            isDirectory: false,
            size: _managedFiles[path]!.length,
            modified: _managedModified[path]!,
          ),
        );
      }
    }
    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  @override
  Future<StoredManagedFile> createManagedFolder({
    String parent = '',
    required String name,
  }) async {
    final safeParent = _safePath(parent, allowRoot: true);
    if (!_managedFolders.contains(safeParent)) {
      throw FormatException('The parent folder does not exist.');
    }
    final safeName = _safeName(name);
    final folderPath = safeParent.isEmpty ? safeName : '$safeParent/$safeName';
    if (_managedFolders.contains(folderPath) ||
        _managedFiles.containsKey(folderPath)) {
      throw FormatException('An item with that name already exists.');
    }
    _managedFolders.add(folderPath);
    return StoredManagedFile(
      path: folderPath,
      name: safeName,
      isDirectory: true,
      size: 0,
      modified: DateTime.now(),
    );
  }

  @override
  Future<StoredManagedFile> importManagedFile({
    String parent = '',
    required String name,
    required Uint8List bytes,
  }) async {
    final safeParent = _safePath(parent, allowRoot: true);
    if (!_managedFolders.contains(safeParent)) {
      throw FormatException('The destination folder does not exist.');
    }
    final safeName = _safeName(name);
    final dot = safeName.lastIndexOf('.');
    final extension = dot > 0 ? safeName.substring(dot) : '';
    final stem = extension.isEmpty
        ? safeName
        : safeName.substring(0, safeName.length - extension.length);
    var candidate = safeName;
    var suffix = 2;
    String filePath() =>
        safeParent.isEmpty ? candidate : '$safeParent/$candidate';
    while (_managedFolders.contains(filePath()) ||
        _managedFiles.containsKey(filePath())) {
      candidate = '$stem ($suffix)$extension';
      suffix++;
    }
    final storedPath = filePath();
    _managedFiles[storedPath] = Uint8List.fromList(bytes);
    final modified = DateTime.now();
    _managedModified[storedPath] = modified;
    return StoredManagedFile(
      path: storedPath,
      name: candidate,
      isDirectory: false,
      size: bytes.length,
      modified: modified,
    );
  }

  @override
  Future<Uint8List> readManagedFile(String relativePath) async {
    final safePath = _safePath(relativePath);
    final bytes = _managedFiles[safePath];
    if (bytes == null) throw FormatException('This file no longer exists.');
    return Uint8List.fromList(bytes);
  }

  @override
  Future<StoredManagedFile> renameManagedFile(
    String relativePath,
    String newName,
  ) async {
    final safePath = _safePath(relativePath);
    final safeName = _safeName(newName);
    final parent = _parentOf(safePath);
    final destination = parent.isEmpty ? safeName : '$parent/$safeName';
    if (safePath != destination &&
        (_managedFolders.contains(destination) ||
            _managedFiles.containsKey(destination))) {
      throw FormatException('An item with that name already exists.');
    }
    final now = DateTime.now();
    if (_managedFiles.containsKey(safePath)) {
      _managedFiles[destination] = _managedFiles.remove(safePath)!;
      final modified = _managedModified.remove(safePath) ?? now;
      _managedModified[destination] = modified;
      return StoredManagedFile(
        path: destination,
        name: safeName,
        isDirectory: false,
        size: _managedFiles[destination]!.length,
        modified: modified,
      );
    }
    if (!_managedFolders.contains(safePath)) {
      throw FormatException('This item no longer exists.');
    }
    final newFolders = _managedFolders
        .where(
          (folder) => folder == safePath || folder.startsWith('$safePath/'),
        )
        .map((folder) => '$destination${folder.substring(safePath.length)}')
        .toList();
    _managedFolders.removeWhere(
      (folder) => folder == safePath || folder.startsWith('$safePath/'),
    );
    _managedFolders.addAll(newFolders);
    final affectedFiles = _managedFiles.keys
        .where((file) => file.startsWith('$safePath/'))
        .toList();
    for (final file in affectedFiles) {
      final newPath = '$destination${file.substring(safePath.length)}';
      _managedFiles[newPath] = _managedFiles.remove(file)!;
      _managedModified[newPath] = _managedModified.remove(file)!;
    }
    return StoredManagedFile(
      path: destination,
      name: safeName,
      isDirectory: true,
      size: 0,
      modified: now,
    );
  }

  @override
  Future<void> moveManagedFileToTrash(String relativePath) async {
    final safePath = _safePath(relativePath);
    final isDirectory = _managedFolders.contains(safePath);
    if (!isDirectory && !_managedFiles.containsKey(safePath)) {
      throw FormatException('This item no longer exists.');
    }
    final prefix = '$safePath/';
    final files = <String, Uint8List>{};
    final modified = <String, DateTime>{};
    for (final file
        in _managedFiles.keys
            .where((file) => file == safePath || file.startsWith(prefix))
            .toList()) {
      files[file] = _managedFiles.remove(file)!;
      modified[file] = _managedModified.remove(file)!;
    }
    final folders = _managedFolders
        .where((folder) => folder == safePath || folder.startsWith(prefix))
        .toSet();
    _managedFolders.removeAll(folders);
    final id =
        '${DateTime.now().toUtc().microsecondsSinceEpoch}_${_trash.length}';
    _trash[id] = _MemoryTrashItem(
      item: StoredTrashItem(
        id: id,
        name: _baseName(safePath),
        originalPath: safePath,
        isDirectory: isDirectory,
        deletedAt: DateTime.now().toUtc(),
      ),
      files: files,
      modified: modified,
      folders: folders,
    );
  }

  @override
  Future<List<StoredTrashItem>> listTrash() async {
    final items = _trash.values.map((item) => item.item).toList();
    items.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return items;
  }

  @override
  Future<void> restoreFromTrash(String id) async {
    final entry = _trash[id];
    if (entry == null) {
      throw FormatException('This trash item no longer exists.');
    }
    final path = entry.item.originalPath;
    if (_managedFiles.containsKey(path) || _managedFolders.contains(path)) {
      throw FormatException(
        'Restore was blocked because an item with that name already exists.',
      );
    }
    var parent = _parentOf(path);
    while (parent.isNotEmpty) {
      _managedFolders.add(parent);
      parent = _parentOf(parent);
    }
    _managedFolders.addAll(entry.folders);
    _managedFiles.addAll(entry.files);
    _managedModified.addAll(entry.modified);
    _trash.remove(id);
  }

  @override
  Future<void> deleteFromTrash(String id) async {
    _trash.remove(id);
  }

  @override
  Future<void> emptyTrash() async {
    _trash.clear();
  }
}

class _MemoryTrashItem {
  const _MemoryTrashItem({
    required this.item,
    required this.files,
    required this.modified,
    required this.folders,
  });

  final StoredTrashItem item;
  final Map<String, Uint8List> files;
  final Map<String, DateTime> modified;
  final Set<String> folders;
}
