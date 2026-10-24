import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mbtiles/mbtiles.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'local_media_store.dart';

LocalMediaStore createLocalMediaStore() => IoLocalMediaStore();

class IoLocalMediaStore implements LocalMediaStore {
  IoLocalMediaStore({Directory? rootDirectory})
    : _rootDirectory = rootDirectory;

  final Directory? _rootDirectory;

  Future<Directory> _supportDirectory() async =>
      _rootDirectory ?? await getApplicationSupportDirectory();

  Future<Directory> _directory(String child) async {
    final supportDirectory = await _supportDirectory();
    final directory = Directory(path.join(supportDirectory.path, child));
    await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> _managedRoot() async =>
      _directory(path.join('workspace_files', 'files'));

  Future<Directory> _trashRoot() async =>
      _directory(path.join('workspace_files', 'trash'));

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
      throw FileSystemException('Choose a valid file or folder name.', name);
    }
    return safeName;
  }

  String _safeBaseName(String name) {
    final baseName = path.basename(name).trim();
    final safeName = baseName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return safeName.isEmpty ? 'imported' : safeName;
  }

  List<String> _safeSegments(String relativePath, {bool allowRoot = false}) {
    if (allowRoot && relativePath.isEmpty) return const [];
    if (relativePath.isEmpty ||
        relativePath.startsWith('/') ||
        relativePath.contains('\\') ||
        relativePath.contains(':') ||
        relativePath.contains('\x00')) {
      throw FileSystemException('Invalid workspace path.', relativePath);
    }
    final segments = relativePath.split('/');
    if (segments.any(
      (segment) =>
          segment.isEmpty ||
          segment == '.' ||
          segment == '..' ||
          segment != _safeName(segment),
    )) {
      throw FileSystemException('Invalid workspace path.', relativePath);
    }
    return segments;
  }

  String _relativePath(List<String> segments) => segments.join('/');

  String _managedPath(
    Directory root,
    String relativePath, {
    bool allowRoot = false,
  }) {
    final segments = _safeSegments(relativePath, allowRoot: allowRoot);
    return path.joinAll([root.path, ...segments]);
  }

  Future<bool> _pathExists(String filePath) async =>
      await FileSystemEntity.type(filePath, followLinks: false) !=
      FileSystemEntityType.notFound;

  Future<StoredManagedFile> _managedEntry(
    FileSystemEntity entity,
    Directory root,
  ) async {
    final isDirectory = entity is Directory;
    final stat = await entity.stat();
    final relative = path.relative(entity.path, from: root.path);
    final normalized = relative.split(path.separator).join('/');
    return StoredManagedFile(
      path: normalized,
      name: path.basename(entity.path),
      isDirectory: isDirectory,
      size: isDirectory ? 0 : stat.size,
      modified: stat.modified,
    );
  }

  String _newTrashId(Directory trashRoot) {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    var suffix = 0;
    while (FileSystemEntity.typeSync(
          path.join(trashRoot.path, '${timestamp}_$suffix'),
          followLinks: false,
        ) !=
        FileSystemEntityType.notFound) {
      suffix++;
    }
    return '${timestamp}_$suffix';
  }

  @override
  Future<StoredScreenshot> addScreenshot({
    required String name,
    required Uint8List bytes,
  }) async {
    final directory = await _directory('screenshots');
    final safeName = _safeBaseName(name);
    final destination = File(
      path.join(
        directory.path,
        '${DateTime.now().toUtc().microsecondsSinceEpoch}_$safeName',
      ),
    );
    await destination.writeAsBytes(bytes, flush: true);
    return StoredScreenshot(name: path.basename(destination.path));
  }

  @override
  Future<StoredOfflineMap> addOfflineMap({
    required String name,
    required Stream<List<int>> bytes,
  }) async {
    final directory = await _directory('offline_maps');
    final safeName = _safeBaseName(name);
    final mapName =
        '${DateTime.now().toUtc().microsecondsSinceEpoch}_$safeName';
    final destination = File(path.join(directory.path, mapName));
    final sink = destination.openWrite();
    try {
      try {
        await sink.addStream(bytes);
      } finally {
        await sink.close();
      }

      final mbTiles = MbTiles(mbtilesPath: destination.path);
      try {
        final metadata = mbTiles.getMetadata();
        if (!const {
          'png',
          'jpg',
          'jpeg',
          'webp',
        }.contains(metadata.format.toLowerCase())) {
          throw FormatException(
            'This map uses ${metadata.format} tiles. Import a raster MBTiles '
            'file (PNG, JPG, or WebP).',
          );
        }
        return StoredOfflineMap(
          id: mapName,
          name: mapName,
          title: metadata.name,
          format: metadata.format,
          attribution: metadata.attributionHtml,
          centerLatitude: metadata.defaultCenter?.latitude,
          centerLongitude: metadata.defaultCenter?.longitude,
          defaultZoom: metadata.defaultZoom,
          minZoom: metadata.minZoom,
          maxZoom: metadata.maxZoom,
        );
      } finally {
        mbTiles.dispose();
      }
    } catch (_) {
      if (await destination.exists()) await destination.delete();
      rethrow;
    }
  }

  @override
  Future<List<StoredOfflineMap>> listOfflineMaps() async {
    final directory = await _directory('offline_maps');
    final maps = <StoredOfflineMap>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.mbtiles')) {
        continue;
      }
      final mbTiles = MbTiles(mbtilesPath: entity.path);
      try {
        final metadata = mbTiles.getMetadata();
        if (!const {
          'png',
          'jpg',
          'jpeg',
          'webp',
        }.contains(metadata.format.toLowerCase())) {
          continue;
        }
        maps.add(
          StoredOfflineMap(
            id: path.basename(entity.path),
            name: path.basename(entity.path),
            title: metadata.name,
            format: metadata.format,
            attribution: metadata.attributionHtml,
            centerLatitude: metadata.defaultCenter?.latitude,
            centerLongitude: metadata.defaultCenter?.longitude,
            defaultZoom: metadata.defaultZoom,
            minZoom: metadata.minZoom,
            maxZoom: metadata.maxZoom,
          ),
        );
      } finally {
        mbTiles.dispose();
      }
    }
    return maps;
  }

  @override
  Future<String?> offlineMapPath(String id) async {
    final directory = await _directory('offline_maps');
    return path.join(directory.path, path.basename(id));
  }

  @override
  Future<void> removeOfflineMap(String id) async {
    final directory = await _directory('offline_maps');
    final file = File(path.join(directory.path, path.basename(id)));
    if (await file.exists()) await file.delete();
  }

  @override
  Future<List<StoredScreenshot>> listScreenshots() async {
    final directory = await _directory('screenshots');
    final screenshots = <StoredScreenshot>[];
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final extension = path.extension(entity.path).toLowerCase();
      if (!const {
        '.png',
        '.jpg',
        '.jpeg',
        '.webp',
        '.gif',
      }.contains(extension)) {
        continue;
      }
      screenshots.add(StoredScreenshot(name: path.basename(entity.path)));
    }
    screenshots.sort((a, b) => b.name.compareTo(a.name));
    return screenshots;
  }

  @override
  Future<void> removeScreenshot(String name) async {
    final directory = await _directory('screenshots');
    final file = File(path.join(directory.path, path.basename(name)));
    if (await file.exists()) await file.delete();
  }

  @override
  Future<Uint8List> readScreenshot(String name) async {
    final directory = await _directory('screenshots');
    final file = File(path.join(directory.path, path.basename(name)));
    return file.readAsBytes();
  }

  @override
  Future<List<StoredManagedFile>> listManagedFiles({String folder = ''}) async {
    final root = await _managedRoot();
    final directoryPath = _managedPath(root, folder, allowRoot: true);
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      throw FileSystemException('This folder no longer exists.', folder);
    }
    final entries = <StoredManagedFile>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File && entity is! Directory) continue;
      entries.add(await _managedEntry(entity, root));
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
    final root = await _managedRoot();
    final parentPath = _managedPath(root, parent, allowRoot: true);
    final parentDirectory = Directory(parentPath);
    if (!await parentDirectory.exists()) {
      throw FileSystemException('The parent folder does not exist.', parent);
    }
    final folderName = _safeName(name);
    final folderPath = path.join(parentPath, folderName);
    if (await _pathExists(folderPath)) {
      throw FileSystemException('An item with that name already exists.', name);
    }
    final directory = await Directory(folderPath).create();
    return _managedEntry(directory, root);
  }

  @override
  Future<StoredManagedFile> importManagedFile({
    String parent = '',
    required String name,
    required Uint8List bytes,
  }) async {
    final root = await _managedRoot();
    final parentPath = _managedPath(root, parent, allowRoot: true);
    if (!await Directory(parentPath).exists()) {
      throw FileSystemException(
        'The destination folder does not exist.',
        parent,
      );
    }
    final fileName = _safeName(name);
    final extension = path.extension(fileName);
    final stem = extension.isEmpty
        ? fileName
        : fileName.substring(0, fileName.length - extension.length);
    var destinationPath = path.join(parentPath, fileName);
    var copyNumber = 2;
    while (await _pathExists(destinationPath)) {
      destinationPath = path.join(parentPath, '$stem ($copyNumber)$extension');
      copyNumber++;
    }
    final file = File(destinationPath);
    await file.writeAsBytes(bytes, flush: true);
    return _managedEntry(file, root);
  }

  @override
  Future<Uint8List> readManagedFile(String relativePath) async {
    final root = await _managedRoot();
    final filePath = _managedPath(root, relativePath);
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('This file no longer exists.', relativePath);
    }
    return file.readAsBytes();
  }

  @override
  Future<StoredManagedFile> renameManagedFile(
    String relativePath,
    String newName,
  ) async {
    final root = await _managedRoot();
    final sourcePath = _managedPath(root, relativePath);
    if (!await _pathExists(sourcePath)) {
      throw FileSystemException('This item no longer exists.', relativePath);
    }
    final name = _safeName(newName);
    final parent = path.dirname(sourcePath);
    final destinationPath = path.join(parent, name);
    if (sourcePath != destinationPath && await _pathExists(destinationPath)) {
      throw FileSystemException('An item with that name already exists.', name);
    }
    final type = await FileSystemEntity.type(sourcePath, followLinks: false);
    final renamed = type == FileSystemEntityType.directory
        ? await Directory(sourcePath).rename(destinationPath)
        : await File(sourcePath).rename(destinationPath);
    return _managedEntry(renamed, root);
  }

  @override
  Future<void> moveManagedFileToTrash(String relativePath) async {
    final root = await _managedRoot();
    final sourcePath = _managedPath(root, relativePath);
    final type = await FileSystemEntity.type(sourcePath, followLinks: false);
    if (type != FileSystemEntityType.file &&
        type != FileSystemEntityType.directory) {
      throw FileSystemException('This item no longer exists.', relativePath);
    }
    final trashRoot = await _trashRoot();
    final id = _newTrashId(trashRoot);
    final itemDirectory = await Directory(path.join(trashRoot.path, id))
        .create();
    final payloadPath = path.join(itemDirectory.path, 'payload');
    final originalPath = _relativePath(_safeSegments(relativePath));
    final metadata = StoredTrashItem(
      id: id,
      name: path.basename(sourcePath),
      originalPath: originalPath,
      isDirectory: type == FileSystemEntityType.directory,
      deletedAt: DateTime.now().toUtc(),
    );
    try {
      await File(path.join(itemDirectory.path, 'item.json')).writeAsString(
        jsonEncode({
          'name': metadata.name,
          'originalPath': metadata.originalPath,
          'isDirectory': metadata.isDirectory,
          'deletedAt': metadata.deletedAt.toIso8601String(),
        }),
        flush: true,
      );
      if (metadata.isDirectory) {
        await Directory(sourcePath).rename(payloadPath);
      } else {
        await File(sourcePath).rename(payloadPath);
      }
    } catch (_) {
      if (await _pathExists(payloadPath) && !await _pathExists(sourcePath)) {
        if (metadata.isDirectory) {
          await Directory(payloadPath).rename(sourcePath);
        } else {
          await File(payloadPath).rename(sourcePath);
        }
      }
      if (await itemDirectory.exists()) {
        await itemDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }

  @override
  Future<List<StoredTrashItem>> listTrash() async {
    final trashRoot = await _trashRoot();
    final items = <StoredTrashItem>[];
    await for (final entity in trashRoot.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final metadataFile = File(path.join(entity.path, 'item.json'));
      if (!await metadataFile.exists()) {
        throw FileSystemException(
          'A Trash entry is missing its recovery information.',
          entity.path,
        );
      }
      final data =
          jsonDecode(await metadataFile.readAsString()) as Map<String, dynamic>;
      final id = path.basename(entity.path);
      final payloadPath = path.join(entity.path, 'payload');
      if (!await _pathExists(payloadPath)) {
        final originalPath = data['originalPath'] as String;
        final root = await _managedRoot();
        if (await _pathExists(_managedPath(root, originalPath))) {
          await entity.delete(recursive: true);
          continue;
        }
        throw FileSystemException(
          'A Trash entry is missing its stored item.',
          entity.path,
        );
      }
      items.add(
        StoredTrashItem(
          id: id,
          name: data['name'] as String,
          originalPath: data['originalPath'] as String,
          isDirectory: data['isDirectory'] as bool,
          deletedAt: DateTime.parse(data['deletedAt'] as String),
        ),
      );
    }
    items.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return items;
  }

  @override
  Future<void> restoreFromTrash(String id) async {
    if (!RegExp(r'^\d+_\d+$').hasMatch(id)) {
      throw FileSystemException('Invalid trash item.');
    }
    final trashRoot = await _trashRoot();
    final itemDirectory = Directory(path.join(trashRoot.path, id));
    final metadataFile = File(path.join(itemDirectory.path, 'item.json'));
    if (!await metadataFile.exists()) {
      throw FileSystemException('This trash item no longer exists.', id);
    }
    final data =
        jsonDecode(await metadataFile.readAsString()) as Map<String, dynamic>;
    final originalPath = data['originalPath'] as String;
    final root = await _managedRoot();
    final destinationPath = _managedPath(root, originalPath);
    if (await _pathExists(destinationPath)) {
      throw FileSystemException(
        'Restore was blocked because an item with that name already exists.',
        originalPath,
      );
    }
    await Directory(path.dirname(destinationPath)).create(recursive: true);
    final payloadPath = path.join(itemDirectory.path, 'payload');
    final isDirectory = data['isDirectory'] as bool;
    if (isDirectory) {
      await Directory(payloadPath).rename(destinationPath);
    } else {
      await File(payloadPath).rename(destinationPath);
    }
    await itemDirectory.delete(recursive: true);
  }

  @override
  Future<void> deleteFromTrash(String id) async {
    if (!RegExp(r'^\d+_\d+$').hasMatch(id)) {
      throw FileSystemException('Invalid trash item.');
    }
    final trashRoot = await _trashRoot();
    final itemDirectory = Directory(path.join(trashRoot.path, id));
    if (await itemDirectory.exists()) {
      await itemDirectory.delete(recursive: true);
    }
  }

  @override
  Future<void> emptyTrash() async {
    final trashRoot = await _trashRoot();
    await for (final entity in trashRoot.list(followLinks: false)) {
      if (entity is Directory) {
        await entity.delete(recursive: true);
      } else if (entity is File) {
        await entity.delete();
      }
    }
  }
}
