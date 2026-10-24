import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mbtiles/mbtiles.dart';
import 'package:white_lotus/data/file_system/local_media_store_io.dart';

void main() {
  late Directory temporaryDirectory;
  late IoLocalMediaStore store;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'white-lotus-media-test-',
    );
    store = IoLocalMediaStore(rootDirectory: temporaryDirectory);
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('screenshots persist locally and can be removed', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final screenshot = await store.addScreenshot(
      name: 'My Screenshot.png',
      bytes: bytes,
    );

    expect(await store.readScreenshot(screenshot.name), bytes);
    expect(
      (await store.listScreenshots()).map((item) => item.name),
      contains(screenshot.name),
    );

    await store.removeScreenshot(screenshot.name);
    expect(await store.listScreenshots(), isEmpty);
  });

  test(
    'managed folders and files can be renamed, trashed, and restored',
    () async {
      final folder = await store.createManagedFolder(name: 'Project images');
      final originalBytes = Uint8List.fromList([7, 8, 9]);
      final file = await store.importManagedFile(
        parent: folder.path,
        name: 'caption.txt',
        bytes: originalBytes,
      );
      expect(file.path, 'Project images/caption.txt');
      expect(await store.readManagedFile(file.path), originalBytes);

      final renamedFolder = await store.renameManagedFile(
        folder.path,
        'Reference images',
      );
      expect(
        (await store.listManagedFiles(folder: renamedFolder.path)).single.name,
        'caption.txt',
      );

      await store.moveManagedFileToTrash(renamedFolder.path);
      final trashedFolder = (await store.listTrash()).single;
      expect(trashedFolder.name, 'Reference images');
      expect(await store.listManagedFiles(), isEmpty);

      await store.restoreFromTrash(trashedFolder.id);
      final restoredFile = (await store.listManagedFiles(
        folder: 'Reference images',
      )).single;
      expect(await store.readManagedFile(restoredFile.path), originalBytes);
      expect(await store.listTrash(), isEmpty);
    },
  );

  test(
    'duplicate imports keep both files and trash can delete permanently',
    () async {
      final first = await store.importManagedFile(
        name: 'notes.txt',
        bytes: Uint8List.fromList([1]),
      );
      final duplicate = await store.importManagedFile(
        name: 'notes.txt',
        bytes: Uint8List.fromList([2]),
      );
      expect(first.name, 'notes.txt');
      expect(duplicate.name, 'notes (2).txt');

      await store.moveManagedFileToTrash(first.path);
      final trashed = (await store.listTrash()).single;
      await store.deleteFromTrash(trashed.id);
      expect(await store.listTrash(), isEmpty);
      expect(await store.listManagedFiles(), hasLength(1));
      expect(
        await store.readManagedFile(duplicate.path),
        Uint8List.fromList([2]),
      );
    },
  );

  test(
    'restoring a trashed file does not overwrite an existing file',
    () async {
      final file = await store.importManagedFile(
        name: 'notes.txt',
        bytes: Uint8List.fromList([1]),
      );
      await store.moveManagedFileToTrash(file.path);
      final trashed = (await store.listTrash()).single;
      await store.importManagedFile(
        name: 'notes.txt',
        bytes: Uint8List.fromList([2]),
      );

      await expectLater(
        store.restoreFromTrash(trashed.id),
        throwsA(
          isA<FileSystemException>().having(
            (error) => error.message,
            'message',
            contains('already exists'),
          ),
        ),
      );
      expect(await store.listTrash(), hasLength(1));
    },
  );

  test('offline raster MBTiles can be imported, listed, and removed', () async {
    final source = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}region.mbtiles',
    );
    final database = MbTiles.create(
      mbtilesPath: source.path,
      metadata: const MbTilesMetadata(name: 'Sample region', format: 'png'),
    );
    database.dispose();

    final imported = await store.addOfflineMap(
      name: 'region.mbtiles',
      bytes: source.openRead(),
    );

    expect(imported.title, 'Sample region');
    expect(imported.format, 'png');
    expect(await store.offlineMapPath(imported.id), isNotNull);
    expect((await store.listOfflineMaps()).single.title, 'Sample region');

    await store.removeOfflineMap(imported.id);
    expect(await store.listOfflineMaps(), isEmpty);
  });

  test('vector MBTiles are rejected with a useful format error', () async {
    final source = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}vector.mbtiles',
    );
    final database = MbTiles.create(
      mbtilesPath: source.path,
      metadata: const MbTilesMetadata(name: 'Vector region', format: 'pbf'),
    );
    database.dispose();

    await expectLater(
      store.addOfflineMap(name: 'vector.mbtiles', bytes: source.openRead()),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('raster MBTiles'),
        ),
      ),
    );
  });
}
