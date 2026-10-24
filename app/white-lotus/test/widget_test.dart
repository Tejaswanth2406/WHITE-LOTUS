// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:white_lotus/app.dart';
import 'package:white_lotus/data/file_system/local_media_store.dart';
import 'package:white_lotus/design_system/blinking_mask.dart';
import 'package:white_lotus/design_system/elastic_slider.dart';
import 'package:white_lotus/design_system/grid_motion.dart';
import 'package:white_lotus/features/dashboard/dashboard_screen.dart';
import 'package:white_lotus/features/files/file_system_screen.dart';
import 'package:white_lotus/features/images/screenshot_gallery_screen.dart';
import 'package:white_lotus/features/maps/offline_maps_screen.dart';

void main() {
  testWidgets('White Lotus overview renders the glass workspace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(WhiteLotusApp(store: _FakeMediaStore()));

    expect(find.text('WHITE LOTUS'), findsOneWidget);
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(BlinkingMask), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/white_lotus_logo.png',
      ),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/dashboard_mask.png',
      ),
      findsOneWidget,
    );
    expect(find.text('Everything in its place.'), findsOneWidget);
    expect(find.text('Open files'), findsOneWidget);
    expect(find.text('BACKGROUND'), findsNothing);
    expect(find.text('Built-in Apps'), findsNothing);
    expect(find.text('28°'), findsNothing);
    expect(find.text('Partly cloudy'), findsNothing);
    expect(find.text('Idea for project'), findsNothing);
    expect(find.text('Voice memo'), findsNothing);
    expect(find.text('HAKARI v4'), findsNothing);
    expect(find.text('Sample: Archive pack'), findsNothing);
    expect(find.text('Weekend in Kyoto'), findsNothing);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('dashboard mask animates its eyelids', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BlinkingMask(
            image: AssetImage('assets/images/dashboard_mask.png'),
            minPause: Duration.zero,
            maxPause: Duration.zero,
            closeDuration: Duration(milliseconds: 100),
            openDuration: Duration(milliseconds: 100),
            doubleBlinkChance: 0,
          ),
        ),
      ),
    );
    final maskPainter = find.descendant(
      of: find.byType(BlinkingMask),
      matching: find.byType(CustomPaint),
    );
    await tester.pump();
    final initialPainter = tester
        .widget<CustomPaint>(maskPainter)
        .painter!;

    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump(const Duration(milliseconds: 40));
    final animatedPainter = tester
        .widget<CustomPaint>(maskPainter)
        .painter!;

    expect(animatedPainter.shouldRepaint(initialPainter), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact layout gives the dashboard room beside menu access', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(WhiteLotusApp(store: _FakeMediaStore()));

    expect(find.text('Everything in its place.'), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('tablet dashboard keeps its two-column panels in bounds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(WhiteLotusApp(store: _FakeMediaStore()));

    expect(find.text('Everything in its place.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Files opens the real local Vault manager', (tester) async {
    await tester.pumpWidget(WhiteLotusApp(store: _FakeMediaStore()));
    await tester.tap(find.text('Files').first);
    await tester.pumpAndSettle();

    expect(find.text('Vault'), findsOneWidget);
    expect(find.text('This folder is empty'), findsOneWidget);
    expect(
      find.text('App-local storage. Files are not password-encrypted yet.'),
      findsOneWidget,
    );
    expect(find.text('New folder'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
  });

  testWidgets('Voices opens the actual audio library without sample items', (
    tester,
  ) async {
    await tester.pumpWidget(WhiteLotusApp(store: _FakeMediaStore()));
    await tester.tap(find.text('Voices').first);
    await tester.pumpAndSettle();

    expect(find.text('Voices'), findsWidgets);
    expect(find.text('No audio in this folder'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
    expect(find.text('Voice memo'), findsNothing);
  });

  testWidgets('wallpaper controls are available in Settings', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(WhiteLotusApp(store: _FakeMediaStore()));

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Use an image'), findsOneWidget);
    expect(find.text('Choose image'), findsOneWidget);
    expect(find.text('Black'), findsOneWidget);
    expect(find.text('Burgundy'), findsOneWidget);
    expect(find.text('Navy blue'), findsOneWidget);
    expect(find.byType(ElasticSlider), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    await tester.drag(find.byType(Slider), const Offset(70, 0));
    await tester.pumpAndSettle();
    expect(find.text('40%'), findsNothing);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('screenshots gallery provides an empty state and import action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ScreenshotGalleryScreen(store: _FakeMediaStore())),
    );
    await tester.pumpAndSettle();

    expect(find.text('No screenshots saved yet'), findsOneWidget);
    expect(find.text('Import screenshots'), findsOneWidget);
  });

  testWidgets('screenshots can be viewed in a local GridMotion collage', (
    tester,
  ) async {
    final imageBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
    );
    final store = _FakeMediaStore(
      screenshots: const [StoredScreenshot(name: 'screen.png')],
      screenshotContents: {'screen.png': imageBytes},
    );
    await tester.pumpWidget(
      MaterialApp(home: ScreenshotGalleryScreen(store: store)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Show motion grid'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(GridMotion), findsOneWidget);
    expect(find.byTooltip('Show screenshot grid'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Files provides navigation, import, and folder controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: FileSystemScreen(store: _FakeMediaStore())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Files'), findsWidgets);
    expect(find.text('This folder is empty'), findsOneWidget);
    expect(find.text('New folder'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
    expect(find.text('Images'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Trash'), findsOneWidget);

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(find.text('Documents & files'), findsOneWidget);
    expect(find.text('Any file'), findsOneWidget);
  });

  testWidgets('Images displays locally stored files in the elastic reel', (
    tester,
  ) async {
    final imageBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
    );
    final store = _FakeMediaStore(
      managedFiles: [
        StoredManagedFile(
          path: 'lotus.png',
          name: 'lotus.png',
          isDirectory: false,
          size: imageBytes.length,
          modified: DateTime(2026),
        ),
      ],
      managedFileContents: {'lotus.png': imageBytes},
    );
    await tester.pumpWidget(MaterialApp(home: FileSystemScreen(store: store)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Images').last);
    await tester.pumpAndSettle();

    expect(find.text('Open image'), findsOneWidget);
    expect(find.text('lotus.png'), findsWidgets);
  });

  testWidgets(
    'offline maps provides an import action when none are installed',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: OfflineMapsScreen(store: _FakeMediaStore())),
      );
      await tester.pumpAndSettle();

      expect(find.text('No offline maps imported'), findsOneWidget);
      expect(find.text('Import MBTiles'), findsOneWidget);
    },
  );
}

class _FakeMediaStore implements LocalMediaStore {
  _FakeMediaStore({
    this.managedFiles = const [],
    this.managedFileContents = const {},
    this.screenshots = const [],
    this.screenshotContents = const {},
  });

  final List<StoredManagedFile> managedFiles;
  final Map<String, Uint8List> managedFileContents;
  final List<StoredScreenshot> screenshots;
  final Map<String, Uint8List> screenshotContents;

  @override
  Future<List<StoredManagedFile>> listManagedFiles({
    String folder = '',
  }) async => managedFiles;

  @override
  Future<StoredManagedFile> createManagedFolder({
    String parent = '',
    required String name,
  }) async => StoredManagedFile(
    path: name,
    name: name,
    isDirectory: true,
    size: 0,
    modified: DateTime.now(),
  );

  @override
  Future<StoredManagedFile> importManagedFile({
    String parent = '',
    required String name,
    required Uint8List bytes,
  }) async => StoredManagedFile(
    path: name,
    name: name,
    isDirectory: false,
    size: bytes.length,
    modified: DateTime.now(),
  );

  @override
  Future<Uint8List> readManagedFile(String relativePath) async =>
      managedFileContents[relativePath] ?? Uint8List(0);

  @override
  Future<StoredManagedFile> renameManagedFile(
    String relativePath,
    String newName,
  ) async => StoredManagedFile(
    path: newName,
    name: newName,
    isDirectory: false,
    size: 0,
    modified: DateTime.now(),
  );

  @override
  Future<void> moveManagedFileToTrash(String relativePath) async {}

  @override
  Future<List<StoredTrashItem>> listTrash() async => const [];

  @override
  Future<void> restoreFromTrash(String id) async {}

  @override
  Future<void> deleteFromTrash(String id) async {}

  @override
  Future<void> emptyTrash() async {}

  @override
  Future<StoredScreenshot> addScreenshot({
    required String name,
    required Uint8List bytes,
  }) async => StoredScreenshot(name: name);

  @override
  Future<StoredOfflineMap> addOfflineMap({
    required String name,
    required Stream<List<int>> bytes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<StoredOfflineMap>> listOfflineMaps() async => const [];

  @override
  Future<List<StoredScreenshot>> listScreenshots() async => screenshots;

  @override
  Future<Uint8List> readScreenshot(String name) async =>
      screenshotContents[name] ??
      (throw StateError('No screenshot named $name'));

  @override
  Future<String?> offlineMapPath(String id) async => null;

  @override
  Future<void> removeOfflineMap(String id) async {}

  @override
  Future<void> removeScreenshot(String name) async {}
}
