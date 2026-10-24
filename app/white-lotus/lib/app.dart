import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/file_system/local_media_store.dart';
import 'features/images/screenshot_gallery_screen.dart';
import 'features/maps/offline_maps_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/devices/devices_screen.dart';
import 'features/files/file_system_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/vault/vault_screen.dart';
import 'features/workspace/workspace_screen.dart';

const _wallpapers = <List<Color>>[
  [Color(0xFF050608), Color(0xFF111319), Color(0xFF20232B)],
  [Color(0xFF16050A), Color(0xFF3A0B18), Color(0xFF61172A)],
  [Color(0xFF061426), Color(0xFF0B2444), Color(0xFF15345D)],
];

class WhiteLotusApp extends StatelessWidget {
  const WhiteLotusApp({super.key, this.store});

  final LocalMediaStore? store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'White Lotus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: MainShell(store: store),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.store});

  final LocalMediaStore? store;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  int _wallpaperIndex = 2;
  double _wallpaperDim = 40;
  Uint8List? _wallpaperImage;

  LocalMediaStore get _store => widget.store ?? localMediaStore;

  static const _items = <_NavItem>[
    _NavItem(Icons.home_rounded, 'Home'),
    _NavItem(Icons.folder_rounded, 'Files'),
    _NavItem(Icons.image_rounded, 'Images'),
    _NavItem(Icons.graphic_eq_rounded, 'Voices'),
    _NavItem(Icons.edit_note_rounded, 'Notes'),
    _NavItem(Icons.map_rounded, 'Maps'),
    _NavItem(Icons.travel_explore_rounded, 'Browser'),
    _NavItem(Icons.download_rounded, 'Torrent'),
    _NavItem(Icons.vpn_lock_rounded, 'VPN'),
    _NavItem(Icons.settings_rounded, 'Settings'),
    _NavItem(Icons.devices_rounded, 'Devices'),
  ];

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final glowColors = _wallpaperImage != null
        ? (const Color(0x447B89A5), const Color(0x333D4A61))
        : switch (_wallpaperIndex) {
            0 => (const Color(0x446A707D), const Color(0x33383D48)),
            1 => (const Color(0x66791A36), const Color(0x44520D23)),
            _ => (const Color(0x665C77F6), const Color(0x554076C5)),
          };
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF07101C),
          gradient: _wallpaperImage == null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _wallpapers[_wallpaperIndex],
                )
              : null,
          image: _wallpaperImage == null
              ? null
              : DecorationImage(
                  image: MemoryImage(_wallpaperImage!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Color.fromRGBO(0, 0, 0, _wallpaperDim / 100),
                    BlendMode.darken,
                  ),
                ),
        ),
        child: Stack(
          children: [
            _AmbientGlow(top: -170, left: 120, color: glowColors.$1),
            _AmbientGlow(bottom: -210, right: 80, color: glowColors.$2),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  return Padding(
                    padding: EdgeInsets.all(compact ? 10 : 18),
                    child: compact
                        ? Column(
                            children: [
                              _CompactTopBar(
                                title: _items[_selectedIndex].label,
                                onMenu: _openCompactMenu,
                              ),
                              const SizedBox(height: 8),
                              Expanded(child: _pageContainer()),
                            ],
                          )
                        : Row(
                            children: [
                              _Sidebar(
                                items: _items,
                                selectedIndex: _selectedIndex,
                                onSelect: _select,
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: _pageContainer()),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageContainer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            border: Border.all(color: Colors.white.withAlpha(20)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _pageForSelection(),
          ),
        ),
      ),
    );
  }

  void _openCompactMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _CompactNavSheet(
        items: _items,
        selectedIndex: _selectedIndex,
        onSelect: (index) {
          _select(index);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  Widget _pageForSelection() {
    return switch (_selectedIndex) {
      0 => DashboardScreen(
        key: const ValueKey('overview'),
        onNavigate: _select,
        store: _store,
      ),
      1 => VaultScreen(key: const ValueKey('vault'), store: _store),
      2 => ScreenshotGalleryScreen(
        key: const ValueKey('screenshots'),
        store: _store,
      ),
      3 => FileSystemScreen(
        key: const ValueKey('voices'),
        title: 'Voices',
        initialAudioView: true,
        store: _store,
      ),
      5 => OfflineMapsScreen(
        key: const ValueKey('offline-maps'),
        store: _store,
      ),
      10 => const DevicesScreen(key: ValueKey('devices')),
      9 => SettingsScreen(
        key: const ValueKey('settings'),
        selectedWallpaperIndex: _wallpaperImage == null ? _wallpaperIndex : -1,
        selectedWallpaperImage: _wallpaperImage,
        wallpaperDim: _wallpaperDim,
        onWallpaperDimChanged: (value) => setState(() {
          _wallpaperDim = value;
        }),
        onSelectWallpaper: (index) => setState(() {
          _wallpaperIndex = index;
          _wallpaperImage = null;
        }),
        onSelectWallpaperImage: (image) => setState(() {
          _wallpaperImage = image;
        }),
      ),
      _ => WorkspaceScreen(
        key: ValueKey(_items[_selectedIndex].label),
        section: switch (_selectedIndex) {
          4 => 'Notes',
          6 => 'Browser',
          7 => 'Torrent',
          8 => 'VPN',
          _ => _items[_selectedIndex].label,
        },
      ),
    };
  }
}

class _CompactTopBar extends StatelessWidget {
  const _CompactTopBar({required this.title, required this.onMenu});

  final String title;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        border: Border.all(color: Colors.white.withAlpha(24)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/white_lotus_logo.png', width: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Open navigation menu',
            onPressed: onMenu,
            icon: const Icon(Icons.menu_rounded),
          ),
        ],
      ),
    );
  }
}

class _CompactNavSheet extends StatelessWidget {
  const _CompactNavSheet({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: MediaQuery.sizeOf(context).height * .72,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xF20B1424),
                border: Border.all(color: Colors.white.withAlpha(30)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ListView(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: _NavButton(
                        item: items[i],
                        selected: selectedIndex == i,
                        onTap: () => onSelect(i),
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
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 190,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(13),
            border: Border.all(color: Colors.white.withAlpha(24)),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Image.asset('assets/images/white_lotus_logo.png'),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'WHITE LOTUS',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 11, bottom: 10),
                  child: Text(
                    'WORKSPACE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: Color(0xFF8795B0),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: _NavButton(
                          item: items[i],
                          selected: selectedIndex == i,
                          onTap: () => onSelect(i),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(9),
                  border: Border.all(color: Colors.white.withAlpha(14)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 18,
                      color: Color(0xFF64D7C8),
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Local mode',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _StatusDot(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white.withAlpha(24) : Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          height: 43,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? Colors.white.withAlpha(28) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 18,
                color: selected
                    ? const Color(0xFF91E7DB)
                    : const Color(0xFFAAB5C9),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : const Color(0xFFB7C1D4),
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF8FE6D8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: const BoxDecoration(
      color: Color(0xFF66D6C5),
      shape: BoxShape.circle,
    ),
  );
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.color,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: 380,
          height: 380,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color, blurRadius: 130, spreadRadius: 35),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}
