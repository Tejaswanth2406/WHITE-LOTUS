import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../../data/file_system/local_media_store.dart';
import '../../design_system/elastic_reel.dart';
import '../../design_system/glass_panel.dart';

enum _FileView { files, images, audio, trash }

enum _ImportType { images, audio, documents, anyFile }

const _documentExtensions = [
  'pdf',
  'txt',
  'md',
  'csv',
  'json',
  'yaml',
  'yml',
  'xml',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'zip',
];

class FileSystemScreen extends StatefulWidget {
  FileSystemScreen({
    super.key,
    LocalMediaStore? store,
    this.title = 'Files',
    this.subtitle,
    this.initialAudioView = false,
  }) : store = store ?? localMediaStore;

  final LocalMediaStore store;
  final String title;
  final String? subtitle;
  final bool initialAudioView;

  @override
  State<FileSystemScreen> createState() => _FileSystemScreenState();
}

class _FileSystemScreenState extends State<FileSystemScreen> {
  List<StoredManagedFile> _entries = const [];
  List<StoredTrashItem> _trash = const [];
  String _folder = '';
  _FileView _view = _FileView.files;
  bool _isLoading = true;
  bool _isImporting = false;
  int _selectedImageIndex = 0;
  String? _imageReelKey;
  Future<List<ElasticReelItem>>? _imageReelFuture;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.initialAudioView) _view = _FileView.audio;
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      if (_view == _FileView.trash) {
        final items = await widget.store.listTrash();
        if (!mounted) return;
        setState(() {
          _trash = items;
          _isLoading = false;
        });
      } else {
        final entries = await widget.store.listManagedFiles(folder: _folder);
        if (!mounted) return;
        setState(() {
          _entries = entries;
          _selectedImageIndex = 0;
          _imageReelKey = null;
          _imageReelFuture = null;
          _isLoading = false;
        });
      }
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _importFiles(_ImportType type) async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: switch (type) {
          _ImportType.images => 'Choose images to import',
          _ImportType.audio => 'Choose audio to import',
          _ImportType.documents => 'Choose files to import',
          _ImportType.anyFile => 'Choose any files to import',
        },
        type: switch (type) {
          _ImportType.images => FileType.image,
          _ImportType.audio => FileType.audio,
          _ImportType.documents => FileType.custom,
          _ImportType.anyFile => FileType.any,
        },
        allowedExtensions: type == _ImportType.documents
            ? _documentExtensions
            : null,
      );
      if (result.isEmpty) return;
      var imported = 0;
      final failures = <String>[];
      for (final file in result) {
        try {
          final bytes = await file.readAsBytes();
          await widget.store.importManagedFile(
            parent: _folder,
            name: file.name,
            bytes: bytes,
          );
          imported++;
        } on Exception catch (error) {
          failures.add('${file.name}: $error');
        }
      }
      await _loadEntries();
      if (!mounted) return;
      if (failures.isNotEmpty) {
        _showMessage(
          '$imported file(s) imported. Could not import: ${failures.join('; ')}',
        );
      } else {
        _showMessage('$imported file(s) added to this folder.');
      }
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'The file picker could not be opened.');
    } on Exception catch (error) {
      _showMessage('Could not import files: $error');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _createFolder() async {
    final name = await _askForName(
      title: 'Create folder',
      label: 'Folder name',
      action: 'Create',
    );
    if (name == null) return;
    try {
      await widget.store.createManagedFolder(parent: _folder, name: name);
      await _loadEntries();
    } on Exception catch (error) {
      _showMessage('Could not create folder: $error');
    }
  }

  Future<void> _rename(StoredManagedFile entry) async {
    final name = await _askForName(
      title: 'Rename item',
      label: 'Name',
      initialValue: entry.name,
      action: 'Rename',
    );
    if (name == null || name == entry.name) return;
    try {
      await widget.store.renameManagedFile(entry.path, name);
      await _loadEntries();
    } on Exception catch (error) {
      _showMessage('Could not rename ${entry.name}: $error');
    }
  }

  Future<String?> _askForName({
    required String title,
    required String label,
    required String action,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(action),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  Future<void> _moveToTrash(StoredManagedFile entry) async {
    try {
      await widget.store.moveManagedFileToTrash(entry.path);
      await _loadEntries();
      _showMessage('${entry.name} moved to Trash.');
    } on Exception catch (error) {
      _showMessage('Could not move ${entry.name} to Trash: $error');
    }
  }

  Future<void> _restore(StoredTrashItem item) async {
    try {
      await widget.store.restoreFromTrash(item.id);
      await _loadEntries();
      _showMessage('${item.name} restored.');
    } on Exception catch (error) {
      _showMessage('Could not restore ${item.name}: $error');
    }
  }

  Future<void> _deleteForever(StoredTrashItem item) async {
    final confirmed = await _confirm(
      title: 'Delete permanently?',
      message:
          '${item.name} will be permanently deleted and cannot be restored.',
      confirmLabel: 'Delete forever',
    );
    if (!confirmed) return;
    try {
      await widget.store.deleteFromTrash(item.id);
      await _loadEntries();
    } on Exception catch (error) {
      _showMessage('Could not permanently delete ${item.name}: $error');
    }
  }

  Future<void> _emptyTrash() async {
    final confirmed = await _confirm(
      title: 'Empty Trash?',
      message: 'All items in Trash will be permanently deleted.',
      confirmLabel: 'Empty Trash',
    );
    if (!confirmed) return;
    try {
      await widget.store.emptyTrash();
      await _loadEntries();
    } on Exception catch (error) {
      _showMessage('Could not empty Trash: $error');
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _open(StoredManagedFile entry) async {
    if (entry.isDirectory) {
      setState(() {
        _folder = entry.path;
        _isLoading = true;
      });
      await _loadEntries();
      return;
    }
    final extension = _extension(entry.name);
    final isImage = _isImage(entry.name);
    final isText = const {
      'txt',
      'md',
      'markdown',
      'json',
      'csv',
      'log',
      'yaml',
      'yml',
      'xml',
      'html',
      'htm',
      'dart',
    }.contains(extension);
    if (isText && entry.size > 1024 * 1024) {
      await _showPreviewDialog(
        entry,
        content: 'Text previews are limited to files under 1 MB.',
      );
      return;
    }
    try {
      final bytes = await widget.store.readManagedFile(entry.path);
      if (isImage) {
        await _showImagePreview(entry, bytes);
      } else if (isText) {
        await _showPreviewDialog(
          entry,
          content: utf8.decode(bytes, allowMalformed: true),
        );
      } else if (_isAudio(entry.name)) {
        await _showPreviewDialog(
          entry,
          content:
              'This audio file is stored locally. In-app audio playback is '
              'not available yet.',
        );
      } else {
        await _showPreviewDialog(
          entry,
          content:
              'Preview is not available for this file type. '
              'The imported file is stored locally.',
        );
      }
    } on Exception catch (error) {
      _showMessage('Could not open ${entry.name}: $error');
    }
  }

  Future<void> _showImagePreview(
    StoredManagedFile entry,
    Uint8List bytes,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(28),
        child: GlassPanel(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.75,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close preview',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Expanded(
                  child: InteractiveViewer(
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('This image could not be displayed.'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPreviewDialog(
    StoredManagedFile entry, {
    required String content,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(28),
        child: GlassPanel(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 650),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close preview',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        content,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  void _selectView(_FileView view) {
    setState(() {
      _view = view;
      _isLoading = true;
    });
    _loadEntries();
  }

  void _navigateToFolder(String folder) {
    setState(() {
      _folder = folder;
      _view = _FileView.files;
      _isLoading = true;
    });
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final heading = switch (_view) {
      _FileView.files => widget.initialAudioView ? 'Files' : widget.title,
      _FileView.images => 'Images',
      _FileView.audio => widget.initialAudioView ? widget.title : 'Audio',
      _FileView.trash => 'Trash',
    };
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
                        Text(
                          heading,
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _view == _FileView.trash
                              ? 'Restore items or delete them permanently.'
                              : widget.subtitle ?? 'Organize files and folders stored on this device.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_view == _FileView.trash)
                    OutlinedButton.icon(
                      onPressed: _trash.isEmpty ? null : _emptyTrash,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Empty Trash'),
                    )
                  else ...[
                    OutlinedButton.icon(
                      onPressed: _createFolder,
                      icon: const Icon(Icons.create_new_folder_outlined),
                      label: const Text('New folder'),
                    ),
                    const SizedBox(width: 9),
                    PopupMenuButton<_ImportType>(
                      enabled: !_isImporting,
                      onSelected: _importFiles,
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _ImportType.images,
                          child: Row(
                            children: [
                              Icon(Icons.image_outlined),
                              SizedBox(width: 12),
                              Text('Images'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: _ImportType.audio,
                          child: Row(
                            children: [
                              Icon(Icons.audio_file_outlined),
                              SizedBox(width: 12),
                              Text('Audio'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: _ImportType.documents,
                          child: Row(
                            children: [
                              Icon(Icons.description_outlined),
                              SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'Documents & files',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: _ImportType.anyFile,
                          child: Row(
                            children: [
                              Icon(Icons.drive_folder_upload_outlined),
                              SizedBox(width: 12),
                              Text('Any file'),
                            ],
                          ),
                        ),
                      ],
                      child: Material(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isImporting)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                const Icon(Icons.file_upload_outlined),
                              const SizedBox(width: 8),
                              Text(_isImporting ? 'Importing…' : 'Import'),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 17),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ViewChip(
                      label: 'Files',
                      icon: Icons.folder_outlined,
                      selected: _view == _FileView.files,
                      onSelected: () => _selectView(_FileView.files),
                    ),
                    const SizedBox(width: 8),
                    _ViewChip(
                      label: 'Images',
                      icon: Icons.image_outlined,
                      selected: _view == _FileView.images,
                      onSelected: () => _selectView(_FileView.images),
                    ),
                    const SizedBox(width: 8),
                    _ViewChip(
                      label: 'Audio',
                      icon: Icons.audio_file_outlined,
                      selected: _view == _FileView.audio,
                      onSelected: () => _selectView(_FileView.audio),
                    ),
                    const SizedBox(width: 8),
                    _ViewChip(
                      label: 'Trash',
                      icon: Icons.delete_outline_rounded,
                      selected: _view == _FileView.trash,
                      onSelected: () => _selectView(_FileView.trash),
                    ),
                  ],
                ),
              ),
              if (_view != _FileView.trash) ...[
                const SizedBox(height: 13),
                _buildBreadcrumbs(),
              ],
              const SizedBox(height: 13),
              Expanded(
                child: GlassPanel(
                  padding: const EdgeInsets.all(14),
                  radius: 20,
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    final segments = _folder.isEmpty ? <String>[] : _folder.split('/');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => _navigateToFolder(''),
            icon: const Icon(Icons.home_outlined, size: 17),
            label: const Text('Files'),
          ),
          for (var index = 0; index < segments.length; index++) ...[
            Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: Colors.white.withAlpha(130),
            ),
            TextButton(
              onPressed: () =>
                  _navigateToFolder(segments.take(index + 1).join('/')),
              child: Text(segments[index]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return _EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Items could not be loaded',
        detail: _loadError!,
        action: OutlinedButton(
          onPressed: _loadEntries,
          child: const Text('Try again'),
        ),
      );
    }
    if (_view == _FileView.trash) return _buildTrash();
    final visibleEntries = switch (_view) {
      _FileView.images =>
        _entries
            .where((entry) => !entry.isDirectory && _isImage(entry.name))
            .toList(),
      _FileView.audio =>
        _entries
            .where((entry) => !entry.isDirectory && _isAudio(entry.name))
            .toList(),
      _ => _entries,
    };
    if (visibleEntries.isEmpty) {
      return _EmptyState(
        icon: switch (_view) {
          _FileView.images => Icons.image_not_supported_outlined,
          _FileView.audio => Icons.audio_file_outlined,
          _ => Icons.folder_open_rounded,
        },
        title: switch (_view) {
          _FileView.images => 'No images in this folder',
          _FileView.audio => 'No audio in this folder',
          _ => 'This folder is empty',
        },
        detail: switch (_view) {
          _FileView.images =>
            'Import images or browse a folder that contains them.',
          _FileView.audio =>
            'Import audio or browse a folder that contains recordings.',
          _ => 'Create a folder or import files to get started.',
        },
      );
    }
    if (_view == _FileView.images) {
      return _buildImageReel(visibleEntries);
    }
    return ListView.separated(
      itemCount: visibleEntries.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.white.withAlpha(18)),
      itemBuilder: (context, index) => _buildFileRow(visibleEntries[index]),
    );
  }

  Future<List<ElasticReelItem>> _loadImageReel(
    List<StoredManagedFile> entries,
  ) async {
    return Future.wait(
      entries.map(
        (entry) async => ElasticReelItem(
          image: MemoryImage(await widget.store.readManagedFile(entry.path)),
          title: entry.name,
        ),
      ),
    );
  }

  Widget _buildImageReel(List<StoredManagedFile> entries) {
    final key = entries.map((entry) => entry.path).join('|');
    if (_imageReelKey != key || _imageReelFuture == null) {
      _imageReelKey = key;
      _imageReelFuture = _loadImageReel(entries);
    }
    final future = _imageReelFuture!;
    return FutureBuilder<List<ElasticReelItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _EmptyState(
            icon: Icons.broken_image_outlined,
            title: 'Images could not be loaded',
            detail: snapshot.error.toString(),
            action: OutlinedButton(
              onPressed: () => setState(() {
                _imageReelKey = null;
                _imageReelFuture = null;
              }),
              child: const Text('Try again'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final selectedIndex = _selectedImageIndex
            .clamp(0, entries.length - 1)
            .toInt();
        return LayoutBuilder(
          builder: (context, constraints) {
            final reelHeight = math.min(360.0, constraints.maxHeight * 0.75);
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: ElasticReel(
                      items: snapshot.data!,
                      height: reelHeight,
                      initialIndex: selectedIndex,
                      expandRatio: 7,
                      spread: 1.8,
                      gap: 7,
                      radius: 16,
                      onSelect: (index) =>
                          setState(() => _selectedImageIndex = index),
                      accentColor: const Color(0xFFECF1FF),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entries[selectedIndex].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _open(entries[selectedIndex]),
                      icon: const Icon(Icons.open_in_full_rounded, size: 15),
                      label: const Text('Open image'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFileRow(StoredManagedFile entry) {
    final icon = entry.isDirectory
        ? Icons.folder_rounded
        : _fileIcon(entry.name);
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 5),
        leading: Icon(
          icon,
          color: entry.isDirectory
              ? const Color(0xFF9FAAFF)
              : const Color(0xFF8FDCCF),
        ),
        title: Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          entry.isDirectory
              ? 'Folder'
              : '${_formatSize(entry.size)}  ·  ${_formatDate(entry.modified)}',
          style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(140)),
        ),
        trailing: _entryMenu(entry),
        onTap: () => _open(entry),
      ),
    );
  }

  Widget _entryMenu(StoredManagedFile entry) => PopupMenuButton<String>(
    tooltip: 'Item actions',
    onSelected: (action) {
      if (action == 'rename') _rename(entry);
      if (action == 'trash') _moveToTrash(entry);
    },
    itemBuilder: (context) => const [
      PopupMenuItem(
        value: 'rename',
        child: Row(
          children: [
            Icon(Icons.drive_file_rename_outline_rounded),
            SizedBox(width: 12),
            Text('Rename'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'trash',
        child: Row(
          children: [
            Icon(Icons.delete_outline_rounded),
            SizedBox(width: 12),
            Text('Move to Trash'),
          ],
        ),
      ),
    ],
  );

  Widget _buildTrash() {
    if (_trash.isEmpty) {
      return const _EmptyState(
        icon: Icons.delete_outline_rounded,
        title: 'Trash is empty',
        detail: 'Items you move to Trash can be restored or deleted forever.',
      );
    }
    return ListView.separated(
      itemCount: _trash.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.white.withAlpha(18)),
      itemBuilder: (context, index) {
        final item = _trash[index];
        return Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 5),
            leading: Icon(
              item.isDirectory
                  ? Icons.folder_delete_outlined
                  : _fileIcon(item.name),
              color: const Color(0xFFFFB6A3),
            ),
            title: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'From ${item.originalPath}  ·  Deleted ${_formatDate(item.deletedAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9, color: Colors.white.withAlpha(140)),
            ),
            trailing: Wrap(
              spacing: 2,
              children: [
                IconButton(
                  tooltip: 'Restore',
                  onPressed: () => _restore(item),
                  icon: const Icon(Icons.restore_rounded),
                ),
                IconButton(
                  tooltip: 'Delete permanently',
                  onPressed: () => _deleteForever(item),
                  icon: const Icon(Icons.delete_forever_outlined),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ViewChip extends StatelessWidget {
  const _ViewChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    avatar: Icon(icon, size: 16),
    label: Text(label),
    selected: selected,
    onSelected: (_) => onSelected(),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: Colors.white.withAlpha(130)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(145)),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    ),
  );
}

String _extension(String name) {
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

bool _isImage(String name) => const {
  'png',
  'jpg',
  'jpeg',
  'webp',
  'gif',
  'bmp',
}.contains(_extension(name));

IconData _fileIcon(String name) {
  if (_isImage(name)) return Icons.image_outlined;
  if (_isAudio(name)) return Icons.audio_file_outlined;
  if (const {
    'txt',
    'md',
    'markdown',
    'json',
    'csv',
    'log',
  }.contains(_extension(name))) {
    return Icons.description_outlined;
  }
  return Icons.insert_drive_file_outlined;
}

bool _isAudio(String name) => const {
  'aac',
  'aiff',
  'alac',
  'flac',
  'm4a',
  'mp3',
  'ogg',
  'opus',
  'wav',
  'wma',
}.contains(_extension(name));

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
