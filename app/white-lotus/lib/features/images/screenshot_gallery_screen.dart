import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../../data/file_system/local_media_store.dart';
import '../../design_system/glass_panel.dart';
import '../../design_system/grid_motion.dart';

class ScreenshotGalleryScreen extends StatefulWidget {
  ScreenshotGalleryScreen({super.key, LocalMediaStore? store})
    : store = store ?? localMediaStore;

  final LocalMediaStore store;

  @override
  State<ScreenshotGalleryScreen> createState() =>
      _ScreenshotGalleryScreenState();
}

class _ScreenshotGalleryScreenState extends State<ScreenshotGalleryScreen> {
  List<StoredScreenshot> _screenshots = const [];
  bool _isLoading = true;
  bool _isImporting = false;
  bool _motionView = false;
  Future<List<ImageProvider>>? _motionImages;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadScreenshots();
  }

  Future<void> _loadScreenshots() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final screenshots = await widget.store.listScreenshots();
      if (!mounted) return;
      setState(() {
        _screenshots = screenshots;
        _isLoading = false;
        _motionImages = null;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _importScreenshots() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Choose screenshots to add',
        type: FileType.image,
      );
      if (result.isEmpty) return;

      for (final file in result) {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          throw FormatException('${file.name} is empty.');
        }
        await widget.store.addScreenshot(name: file.name, bytes: bytes);
      }
      if (!mounted) return;
      await _loadScreenshots();
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'The file picker could not be opened.');
    } on Exception catch (error) {
      _showMessage('Could not save screenshots: $error');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _removeScreenshot(StoredScreenshot screenshot) async {
    try {
      await widget.store.removeScreenshot(screenshot.name);
      await _loadScreenshots();
    } on Exception catch (error) {
      _showMessage('Could not remove ${screenshot.name}: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(27),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Screenshots',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Keep screenshots on this device. They are not '
                          'encrypted yet.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _motionView
                        ? 'Show screenshot grid'
                        : 'Show motion grid',
                    onPressed: _screenshots.isEmpty
                        ? null
                        : () => setState(() {
                            _motionView = !_motionView;
                            _motionImages ??= _loadMotionImages();
                          }),
                    icon: Icon(
                      _motionView
                          ? Icons.grid_view_rounded
                          : Icons.motion_photos_on_rounded,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isImporting ? null : _importScreenshots,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate_rounded),
                    label: Text(
                      _isImporting ? 'Saving…' : 'Import screenshots',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GlassPanel(
                  padding: const EdgeInsets.all(14),
                  radius: 20,
                  child: _buildGallery(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGallery() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Screenshots could not be loaded.',
              style: TextStyle(color: Colors.white.withAlpha(210)),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError!,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withAlpha(135),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadScreenshots,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    if (_screenshots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.screenshot_monitor_rounded,
              size: 38,
              color: Colors.white.withAlpha(130),
            ),
            const SizedBox(height: 10),
            const Text(
              'No screenshots saved yet',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              'Import screenshots from your device to keep them here.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withAlpha(145),
              ),
            ),
          ],
        ),
      );
    }
    if (_motionView) return _buildMotionGallery();
    return GridView.builder(
      itemCount: _screenshots.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final screenshot = _screenshots[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ColoredBox(
            color: Colors.white.withAlpha(8),
            child: Column(
              children: [
                Expanded(
                  child: FutureBuilder(
                    future: widget.store.readScreenshot(screenshot.name),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Tooltip(
                            message:
                                'Could not read screenshot: '
                                '${snapshot.error}',
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          screenshot.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove screenshot',
                        onPressed: () => _removeScreenshot(screenshot),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<ImageProvider>> _loadMotionImages() async {
    final bytes = await Future.wait(
      _screenshots.map(
        (screenshot) => widget.store.readScreenshot(screenshot.name),
      ),
    );
    return bytes.map(MemoryImage.new).toList(growable: false);
  }

  Widget _buildMotionGallery() {
    return FutureBuilder<List<ImageProvider>>(
      future: _motionImages,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.broken_image_outlined),
                const SizedBox(height: 8),
                const Text('Screenshots could not be loaded.'),
                TextButton(
                  onPressed: () => setState(() {
                    _motionImages = _loadMotionImages();
                  }),
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return GridMotion(
          items: snapshot.data!,
          rows: 4,
          aspectRatio: 1.45,
          gap: 10,
          radius: 14,
          speed: 20,
          parallax: .35,
          dim: .18,
          borderColor: Colors.white.withAlpha(30),
        );
      },
    );
  }
}
