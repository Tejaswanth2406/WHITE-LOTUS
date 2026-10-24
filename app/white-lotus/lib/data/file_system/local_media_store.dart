import 'dart:typed_data';

import 'local_media_store_stub.dart'
    if (dart.library.io) 'local_media_store_io.dart'
    as platform_store;

class StoredScreenshot {
  const StoredScreenshot({required this.name});

  final String name;
}

class StoredOfflineMap {
  const StoredOfflineMap({
    required this.id,
    required this.name,
    required this.title,
    required this.format,
    required this.attribution,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.defaultZoom,
    required this.minZoom,
    required this.maxZoom,
  });

  final String id;
  final String name;
  final String title;
  final String format;
  final String? attribution;
  final double? centerLatitude;
  final double? centerLongitude;
  final double? defaultZoom;
  final double? minZoom;
  final double? maxZoom;
}

class StoredManagedFile {
  const StoredManagedFile({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.modified,
  });

  final String path;
  final String name;
  final bool isDirectory;
  final int size;
  final DateTime modified;
}

class StoredTrashItem {
  const StoredTrashItem({
    required this.id,
    required this.name,
    required this.originalPath,
    required this.isDirectory,
    required this.deletedAt,
  });

  final String id;
  final String name;
  final String originalPath;
  final bool isDirectory;
  final DateTime deletedAt;
}

abstract interface class LocalMediaStore {
  Future<List<StoredScreenshot>> listScreenshots();

  Future<StoredScreenshot> addScreenshot({
    required String name,
    required Uint8List bytes,
  });

  Future<Uint8List> readScreenshot(String name);

  Future<void> removeScreenshot(String name);

  Future<List<StoredManagedFile>> listManagedFiles({String folder = ''});

  Future<StoredManagedFile> createManagedFolder({
    String parent = '',
    required String name,
  });

  Future<StoredManagedFile> importManagedFile({
    String parent = '',
    required String name,
    required Uint8List bytes,
  });

  Future<Uint8List> readManagedFile(String relativePath);

  Future<StoredManagedFile> renameManagedFile(
    String relativePath,
    String newName,
  );

  Future<void> moveManagedFileToTrash(String relativePath);

  Future<List<StoredTrashItem>> listTrash();

  Future<void> restoreFromTrash(String id);

  Future<void> deleteFromTrash(String id);

  Future<void> emptyTrash();

  Future<List<StoredOfflineMap>> listOfflineMaps();

  Future<StoredOfflineMap> addOfflineMap({
    required String name,
    required Stream<List<int>> bytes,
  });

  Future<void> removeOfflineMap(String id);

  Future<String?> offlineMapPath(String id);
}

final LocalMediaStore localMediaStore = platform_store.createLocalMediaStore();
