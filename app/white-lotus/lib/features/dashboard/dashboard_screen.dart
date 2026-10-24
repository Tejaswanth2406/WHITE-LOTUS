import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/file_system/local_media_store.dart';
import '../../design_system/glass_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onNavigate, this.store});

  final ValueChanged<int> onNavigate;
  final LocalMediaStore? store;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _focusMode = false;

  LocalMediaStore get _store => widget.store ?? localMediaStore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 18,
              12,
              compact ? 12 : 18,
              16,
            ),
            child: Column(
              children: [
                _HeaderBar(
                  focusMode: _focusMode,
                  onFocusChanged: (value) => setState(() => _focusMode = value),
                ),
                const SizedBox(height: 10),
                _MaskHeroPanel(
                  compact: compact,
                  onOpenFiles: () => widget.onNavigate(1),
                ),
                const SizedBox(height: 10),
                if (compact)
                  _buildCompactOverview()
                else if (constraints.maxWidth < 1000)
                  _buildTabletOverview(constraints.maxWidth)
                else
                  _buildDesktopOverview(constraints.maxWidth),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactOverview() {
    return Column(
      children: [
        _ShortcutsRow(onNavigate: widget.onNavigate),
        const SizedBox(height: 8),
        SizedBox(
          height: 184,
          child: _FilesPanel(store: _store, onNavigate: widget.onNavigate),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 132,
          child: _ImagePanel(store: _store, onNavigate: widget.onNavigate),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: _MapPanel(store: _store, onNavigate: widget.onNavigate),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 158,
          child: _VoicePanel(store: _store, onNavigate: widget.onNavigate),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 132,
          child: _NotesPanel(onNavigate: widget.onNavigate),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 172,
          child: _QuickActionsPanel(onNavigate: widget.onNavigate),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 105,
          child: _SecurityPanel(onNavigate: widget.onNavigate),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 145,
          child: _TransferPanel(onNavigate: widget.onNavigate),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 85,
          child: _BrowserPanel(onNavigate: widget.onNavigate),
        ),
      ],
    );
  }

  Widget _buildTabletOverview(double width) {
    final contentWidth = width - 40;
    final columnWidth = (contentWidth - 12) / 2;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: columnWidth,
          child: Column(
            children: [
              SizedBox(
                height: 188,
                child: _FilesPanel(
                  store: _store,
                  onNavigate: widget.onNavigate,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: _VoicePanel(
                  store: _store,
                  onNavigate: widget.onNavigate,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 130,
                child: _ImagePanel(
                  store: _store,
                  onNavigate: widget.onNavigate,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 84,
                child: _BrowserPanel(onNavigate: widget.onNavigate),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: columnWidth,
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: _MapPanel(store: _store, onNavigate: widget.onNavigate),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 132,
                child: _NotesPanel(onNavigate: widget.onNavigate),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 166,
                child: _QuickActionsPanel(onNavigate: widget.onNavigate),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 104,
                child: _SecurityPanel(onNavigate: widget.onNavigate),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 148,
                child: _TransferPanel(onNavigate: widget.onNavigate),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopOverview(double width) {
    final contentWidth = width - 40;
    final availableGridWidth = contentWidth - 22;
    final leftWidth = availableGridWidth * .42;
    final centerWidth = availableGridWidth * .30;
    final rightWidth = availableGridWidth * .28;

    return Column(
      children: [
        SizedBox(
          height: 82,
          child: _ShortcutsRow(onNavigate: widget.onNavigate),
        ),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: leftWidth,
              child: Column(
                children: [
                  SizedBox(
                    height: 204,
                    child: _FilesPanel(
                      store: _store,
                      onNavigate: widget.onNavigate,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 165,
                    child: _VoicePanel(
                      store: _store,
                      onNavigate: widget.onNavigate,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 84,
                    child: _BrowserPanel(onNavigate: widget.onNavigate),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),
            SizedBox(
              width: centerWidth,
              child: Column(
                children: [
                  SizedBox(
                    height: 138,
                    child: _ImagePanel(
                      store: _store,
                      onNavigate: widget.onNavigate,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 138,
                    child: _NotesPanel(onNavigate: widget.onNavigate),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 185,
                    child: _MapPanel(
                      store: _store,
                      onNavigate: widget.onNavigate,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),
            SizedBox(
              width: rightWidth,
              child: Column(
                children: [
                  SizedBox(
                    height: 166,
                    child: _QuickActionsPanel(onNavigate: widget.onNavigate),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 104,
                    child: _SecurityPanel(onNavigate: widget.onNavigate),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 148,
                    child: _TransferPanel(onNavigate: widget.onNavigate),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MaskHeroPanel extends StatelessWidget {
  const _MaskHeroPanel({required this.compact, required this.onOpenFiles});

  final bool compact;
  final VoidCallback onOpenFiles;

  @override
  Widget build(BuildContext context) {
    final maskSize = compact ? 108.0 : 128.0;
    return SizedBox(
      height: compact ? 146 : 154,
      child: GlassPanel(
        padding: EdgeInsets.fromLTRB(compact ? 16 : 22, 12, 18, 12),
        radius: 20,
        tint: const Color(0xFF541322),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'YOUR PRIVATE SPACE',
                    style: TextStyle(
                      color: Colors.white.withAlpha(155),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Everything in its place.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withAlpha(245),
                      fontSize: compact ? 18 : 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your files, notes and maps — together.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withAlpha(170),
                      fontSize: compact ? 9 : 11,
                    ),
                  ),
                  const SizedBox(height: 9),
                  InkWell(
                    onTap: onOpenFiles,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(45)),
                      ),
                      child: const Text(
                        'Open files',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: maskSize + 14,
              height: maskSize + 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(12),
                border: Border.all(color: Colors.white.withAlpha(36)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withAlpha(20),
                    blurRadius: 26,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  'assets/images/white_lotus_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.focusMode, required this.onFocusChanged});

  final bool focusMode;
  final ValueChanged<bool> onFocusChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: Row(
        children: [
          Expanded(
            child: GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              radius: 13,
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 15,
                    color: Color(0xFFAFBAD0),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search files, notes, apps, or the web…',
                        hintStyle: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withAlpha(115),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_return_rounded,
                    size: 13,
                    color: Colors.white.withAlpha(110),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PillButton(
            icon: focusMode ? Icons.nightlight_round : Icons.dark_mode_outlined,
            label: 'Focus mode',
            selected: focusMode,
            onTap: () => onFocusChanged(!focusMode),
          ),
          const SizedBox(width: 5),
          _HeaderIcon(icon: Icons.settings_outlined, onTap: () {}),
          _HeaderIcon(icon: Icons.remove_rounded, onTap: () {}),
          _HeaderIcon(icon: Icons.crop_square_rounded, onTap: () {}),
        ],
      ),
    );
  }
}

class _ShortcutsRow extends StatelessWidget {
  const _ShortcutsRow({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    const shortcuts = [
      (
        Icons.folder_rounded,
        'Files',
        'Browse & organize',
        1,
        Color(0xFF7BB8FF),
      ),
      (Icons.image_rounded, 'Images', 'View & edit', 2, Color(0xFF9EA4FF)),
      (
        Icons.graphic_eq_rounded,
        'Voices',
        'Record & play',
        3,
        Color(0xFFBB8FFF),
      ),
      (
        Icons.sticky_note_2_rounded,
        'Notes',
        'Quick notes',
        4,
        Color(0xFFE1A4FF),
      ),
      (
        Icons.location_on_rounded,
        'Maps',
        'Explore & pin',
        5,
        Color(0xFF70D9D4),
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < shortcuts.length; i++) ...[
          if (i != 0) const SizedBox(width: 8),
          Expanded(
            child: _ShortcutTile(
              icon: shortcuts[i].$1,
              title: shortcuts[i].$2,
              subtitle: shortcuts[i].$3,
              color: shortcuts[i].$5,
              onTap: () => onNavigate(shortcuts[i].$4),
            ),
          ),
        ],
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: GlassPanel(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          radius: 16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 23, color: color),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 7,
                  color: Colors.white.withAlpha(135),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilesPanel extends StatefulWidget {
  const _FilesPanel({required this.store, required this.onNavigate});

  final LocalMediaStore store;
  final ValueChanged<int> onNavigate;

  @override
  State<_FilesPanel> createState() => _FilesPanelState();
}

class _FilesPanelState extends State<_FilesPanel> {
  late Future<List<StoredManagedFile>> _files;

  @override
  void initState() {
    super.initState();
    _files = widget.store.listManagedFiles();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(12),
      radius: 17,
      child: Column(
        children: [
          _PanelHeader(
            title: 'Vault files',
            icon: Icons.folder_rounded,
            action: 'Open',
            onTap: () => widget.onNavigate(1),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<StoredManagedFile>>(
              future: _files,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Vault files could not be loaded.',
                      style: TextStyle(fontSize: 9),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final entries = snapshot.data!;
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.folder_open_rounded,
                          size: 24,
                          color: Color(0xFF90B9EC),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Your vault is empty',
                          style: TextStyle(fontSize: 9),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigate(1),
                          child: const Text(
                            'Import or create a folder',
                            style: TextStyle(fontSize: 8),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: entries.length < 4 ? entries.length : 4,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: Colors.white.withAlpha(18)),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return InkWell(
                      onTap: () => widget.onNavigate(1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              entry.isDirectory
                                  ? Icons.folder_rounded
                                  : Icons.insert_drive_file_rounded,
                              size: 17,
                              color: const Color(0xFF90B9EC),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 15,
                              color: Color(0xFF9AA6BB),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePanel extends StatefulWidget {
  const _ImagePanel({required this.store, required this.onNavigate});

  final LocalMediaStore store;
  final ValueChanged<int> onNavigate;

  @override
  State<_ImagePanel> createState() => _ImagePanelState();
}

class _ImagePanelState extends State<_ImagePanel> {
  late Future<List<StoredScreenshot>> _screenshots;

  @override
  void initState() {
    super.initState();
    _screenshots = widget.store.listScreenshots();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(11),
      radius: 17,
      child: Column(
        children: [
          _PanelHeader(
            title: 'Screenshots',
            icon: Icons.image_rounded,
            action: 'View all',
            onTap: () => widget.onNavigate(2),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<StoredScreenshot>>(
              future: _screenshots,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Screenshots could not be loaded.',
                      style: TextStyle(fontSize: 8),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final screenshots = snapshot.data!;
                if (screenshots.isEmpty) {
                  return Center(
                    child: TextButton.icon(
                      onPressed: () => widget.onNavigate(2),
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('No screenshots yet'),
                    ),
                  );
                }
                return Row(
                  children: [
                    for (final screenshot in screenshots.take(3))
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _ScreenshotThumbnail(
                            store: widget.store,
                            screenshot: screenshot,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenshotThumbnail extends StatefulWidget {
  const _ScreenshotThumbnail({required this.store, required this.screenshot});

  final LocalMediaStore store;
  final StoredScreenshot screenshot;

  @override
  State<_ScreenshotThumbnail> createState() => _ScreenshotThumbnailState();
}

class _ScreenshotThumbnailState extends State<_ScreenshotThumbnail> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.store.readScreenshot(widget.screenshot.name);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.expand(
        child: FutureBuilder<Uint8List>(
          future: _bytes,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const ColoredBox(
                color: Color(0x223D526D),
                child: Center(
                  child: Icon(Icons.broken_image_outlined, size: 18),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const ColoredBox(
                color: Color(0x223D526D),
                child: Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
              );
            }
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0x223D526D),
                child: Center(
                  child: Icon(Icons.broken_image_outlined, size: 18),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VoicePanel extends StatefulWidget {
  const _VoicePanel({required this.store, required this.onNavigate});

  final LocalMediaStore store;
  final ValueChanged<int> onNavigate;

  @override
  State<_VoicePanel> createState() => _VoicePanelState();
}

class _VoicePanelState extends State<_VoicePanel> {
  late Future<List<StoredManagedFile>> _files;

  @override
  void initState() {
    super.initState();
    _files = widget.store.listManagedFiles();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(12),
      radius: 17,
      child: Column(
        children: [
          _PanelHeader(
            title: 'Voices',
            icon: Icons.graphic_eq_rounded,
            action: 'Open',
            onTap: () => widget.onNavigate(3),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<StoredManagedFile>>(
              future: _files,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Audio files could not be loaded.',
                      style: TextStyle(fontSize: 8),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final audioFiles = snapshot.data!
                    .where(
                      (entry) => !entry.isDirectory && _isAudioFile(entry.name),
                    )
                    .take(3)
                    .toList();
                if (audioFiles.isEmpty) {
                  return Center(
                    child: TextButton.icon(
                      onPressed: () => widget.onNavigate(3),
                      icon: const Icon(Icons.audio_file_outlined),
                      label: const Text('No audio imported'),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: audioFiles.length,
                  itemBuilder: (context, index) {
                    final file = audioFiles[index];
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.audio_file_outlined,
                          color: Color(0xFF9BB5FF),
                        ),
                        title: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Imported audio · playback not available',
                          style: TextStyle(fontSize: 7),
                        ),
                        onTap: () => widget.onNavigate(3),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesPanel extends StatelessWidget {
  const _NotesPanel({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(12),
      radius: 17,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'Notes',
            icon: Icons.sticky_note_2_rounded,
            action: 'View all',
            onTap: () => onNavigate(4),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: Center(
              child: TextButton.icon(
                onPressed: () => onNavigate(4),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text(
                  'No saved notes yet',
                  style: TextStyle(fontSize: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPanel extends StatefulWidget {
  const _MapPanel({required this.store, required this.onNavigate});

  final LocalMediaStore store;
  final ValueChanged<int> onNavigate;

  @override
  State<_MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<_MapPanel> {
  late Future<List<StoredOfflineMap>> _maps;

  @override
  void initState() {
    super.initState();
    _maps = widget.store.listOfflineMaps();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(12),
      radius: 17,
      child: Column(
        children: [
          _PanelHeader(
            title: 'Maps',
            icon: Icons.location_on_rounded,
            action: 'Open',
            onTap: () => widget.onNavigate(5),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<StoredOfflineMap>>(
              future: _maps,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Offline maps could not be loaded.',
                      style: TextStyle(fontSize: 8),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                final maps = snapshot.data!;
                if (maps.isEmpty) {
                  return Center(
                    child: TextButton.icon(
                      onPressed: () => widget.onNavigate(5),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text(
                        'No offline maps yet',
                        style: TextStyle(fontSize: 8),
                      ),
                    ),
                  );
                }
                return ListView(
                  children: [
                    for (final map in maps.take(3))
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.map_rounded,
                            color: Color(0xFF70D9D4),
                          ),
                          title: Text(
                            map.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9),
                          ),
                          subtitle: Text(
                            '${map.format.toUpperCase()} offline map',
                            style: const TextStyle(fontSize: 7),
                          ),
                          onTap: () => widget.onNavigate(5),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Open Maps to place multiple pins.',
              style: TextStyle(fontSize: 7, color: Colors.white.withAlpha(150)),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isAudioFile(String name) {
  final lowerName = name.toLowerCase();
  return const [
    '.mp3',
    '.wav',
    '.m4a',
    '.aac',
    '.ogg',
    '.flac',
    '.opus',
  ].any(lowerName.endsWith);
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.sticky_note_2_rounded, 'New Note', 4),
      (Icons.audio_file_outlined, 'Open Audio', 3),
      (Icons.vpn_lock_rounded, 'Open VPN', 9),
      (Icons.download_rounded, 'Open Torrent', 7),
    ];
    return GlassPanel(
      padding: const EdgeInsets.all(11),
      radius: 17,
      child: Column(
        children: [
          const _PanelHeader(
            title: 'Quick Actions',
            icon: Icons.bolt_rounded,
            action: '×',
          ),
          const SizedBox(height: 8),
          for (final action in actions)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Material(
                  color: Colors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => onNavigate(action.$3),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Icon(
                            action.$1,
                            size: 14,
                            color: const Color(0xFF90DCD6),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              action.$2,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 13),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SecurityPanel extends StatelessWidget {
  const _SecurityPanel({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(11),
      radius: 17,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'VPN',
            icon: Icons.shield_rounded,
            action: '×',
            onTap: () => onNavigate(9),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: Color(0xFFFFC782)),
              const SizedBox(width: 6),
              Text(
                'Not connected',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.white.withAlpha(195),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'VPN service planned',
            style: TextStyle(fontSize: 7, color: Colors.white.withAlpha(135)),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 25,
            child: OutlinedButton(
              onPressed: () => onNavigate(9),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withAlpha(42)),
              ),
              child: const Text('Configure', style: TextStyle(fontSize: 8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferPanel extends StatelessWidget {
  const _TransferPanel({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(11),
      radius: 17,
      child: Column(
        children: [
          _PanelHeader(
            title: 'Torrent',
            icon: Icons.swap_vert_rounded,
            action: 'Open',
            onTap: () => onNavigate(7),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: Color(0xFFFFC782),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'No torrent service connected',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 8),
                  ),
                  TextButton(
                    onPressed: () => onNavigate(7),
                    child: const Text(
                      'View status',
                      style: TextStyle(fontSize: 8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowserPanel extends StatelessWidget {
  const _BrowserPanel({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      radius: 16,
      child: Row(
        children: [
          const Icon(
            Icons.language_rounded,
            size: 16,
            color: Color(0xFF83C9FF),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Browser  ·  private browsing & ad blocking planned',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 8, color: Colors.white.withAlpha(180)),
            ),
          ),
          _SmallIconButton(
            icon: Icons.arrow_forward_rounded,
            onTap: () => onNavigate(6),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.icon,
    required this.action,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF8DBDFF)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ),
        InkWell(
          onTap: onTap,
          child: Text(
            action,
            style: TextStyle(fontSize: 7, color: Colors.white.withAlpha(160)),
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white.withAlpha(28) : Colors.white.withAlpha(11),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(icon, size: 11),
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(fontSize: 8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 25, minHeight: 25),
      icon: Icon(icon, size: 13, color: Colors.white.withAlpha(175)),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(42),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          width: 22,
          height: 22,
          child: Icon(icon, size: 12, color: Colors.white.withAlpha(200)),
        ),
      ),
    );
  }
}
