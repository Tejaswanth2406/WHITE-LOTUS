import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:latlong2/latlong.dart';

import '../../data/file_system/local_media_store.dart';
import '../../design_system/glass_panel.dart';

class OfflineMapsScreen extends StatefulWidget {
  OfflineMapsScreen({super.key, LocalMediaStore? store})
    : store = store ?? localMediaStore;

  final LocalMediaStore store;

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  List<StoredOfflineMap> _maps = const [];
  String? _selectedMapId;
  bool _isLoading = true;
  bool _isImporting = false;
  String? _loadError;

  StoredOfflineMap? get _selectedMap {
    for (final map in _maps) {
      if (map.id == _selectedMapId) return map;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadMaps();
  }

  Future<void> _loadMaps() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final maps = await widget.store.listOfflineMaps();
      if (!mounted) return;
      setState(() {
        _maps = maps;
        if (!maps.any((map) => map.id == _selectedMapId)) {
          _selectedMapId = maps.isEmpty ? null : maps.first.id;
        }
        _isLoading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _importMap() async {
    if (kIsWeb) {
      _showMessage(
        'Offline MBTiles maps are available in desktop and mobile builds.',
      );
      return;
    }

    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.pickFile(
        dialogTitle: 'Choose a raster MBTiles map',
        type: FileType.custom,
        allowedExtensions: const ['mbtiles'],
      );
      if (result == null) return;

      final map = await widget.store.addOfflineMap(
        name: result.name,
        bytes: result.xFile.openRead(),
      );
      if (!mounted) return;
      setState(() {
        _maps = [map, ..._maps];
        _selectedMapId = map.id;
      });
      _showMessage('${map.title} is ready for offline use.');
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'The file picker could not be opened.');
    } on Exception catch (error) {
      _showMessage('Could not import this map: $error');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _removeMap(StoredOfflineMap map) async {
    try {
      if (_selectedMapId == map.id) {
        setState(() => _selectedMapId = null);
        await WidgetsBinding.instance.endOfFrame;
      }
      await widget.store.removeOfflineMap(map.id);
      await _loadMaps();
    } on Exception catch (error) {
      _showMessage('Could not remove ${map.title}: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final selectedMap = _selectedMap;
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
                  const Expanded(child: _MapsHeading()),
                  OutlinedButton.icon(
                    onPressed: _isImporting ? null : _importMap,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(
                      _isImporting ? 'Importing…' : 'Import offline map',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_maps.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedMapId,
                        decoration: const InputDecoration(
                          labelText: 'Offline map',
                          isDense: true,
                        ),
                        items: [
                          for (final map in _maps)
                            DropdownMenuItem(
                              value: map.id,
                              child: Text(
                                map.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedMapId = value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Remove selected offline map',
                      onPressed: selectedMap == null
                          ? null
                          : () => _removeMap(selectedMap),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: GlassPanel(
                  padding: EdgeInsets.zero,
                  radius: 22,
                  child: _buildMapContent(selectedMap),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Offline raster MBTiles are stored on this device. Tap the map '
                'to place pins.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withAlpha(140),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapContent(StoredOfflineMap? map) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return _MessagePanel(
        icon: Icons.error_outline_rounded,
        title: 'Offline maps could not be loaded',
        message: _loadError!,
        actionLabel: 'Try again',
        onAction: _loadMaps,
      );
    }
    if (map == null) {
      return _MessagePanel(
        icon: Icons.public_rounded,
        title: 'No offline maps imported',
        message: kIsWeb
            ? 'Open White Lotus in a desktop or mobile build to import and '
                  'use offline MBTiles maps.'
            : 'Import a raster MBTiles region package to view detailed streets '
                  'and places without a network connection. MBTiles packages '
                  'must be obtained from a map provider that permits offline use.',
        actionLabel: kIsWeb ? null : 'Import MBTiles',
        onAction: kIsWeb ? null : _importMap,
      );
    }
    if (kIsWeb) {
      return const _MessagePanel(
        icon: Icons.public_rounded,
        title: 'Offline maps need a desktop or mobile build',
        message:
            'MBTiles storage uses a local SQLite database and is not '
            'available in the web preview.',
      );
    }
    return FutureBuilder<String?>(
      future: widget.store.offlineMapPath(map.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MessagePanel(
            icon: Icons.error_outline_rounded,
            title: 'Map file could not be opened',
            message: snapshot.error.toString(),
          );
        }
        final path = snapshot.data;
        if (path == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _OfflineMapView(key: ValueKey(map.id), map: map, path: path);
      },
    );
  }
}

class _MapsHeading extends StatelessWidget {
  const _MapsHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Offline Maps',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          'Bring your detailed map regions with you.',
          style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(150)),
        ),
      ],
    );
  }
}

class _OfflineMapView extends StatefulWidget {
  const _OfflineMapView({super.key, required this.map, required this.path});

  final StoredOfflineMap map;
  final String path;

  @override
  State<_OfflineMapView> createState() => _OfflineMapViewState();
}

class _OfflineMapViewState extends State<_OfflineMapView> {
  late final MbTilesTileProvider _tileProvider = MbTilesTileProvider.fromPath(
    path: widget.path,
    silenceTileNotFound: true,
  );
  final List<LatLng> _pins = [];

  @override
  Widget build(BuildContext context) {
    final map = widget.map;
    final center = map.centerLatitude != null && map.centerLongitude != null
        ? LatLng(map.centerLatitude!, map.centerLongitude!)
        : const LatLng(20, 0);
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: map.defaultZoom ?? 3,
              minZoom: map.minZoom ?? 1,
              maxZoom: map.maxZoom ?? 18,
              onTap: (_, point) => setState(() => _pins.add(point)),
            ),
            children: [
              TileLayer(
                tileProvider: _tileProvider,
                maxZoom: map.maxZoom ?? 18,
              ),
              MarkerLayer(
                markers: [
                  for (var i = 0; i < _pins.length; i++)
                    Marker(
                      point: _pins[i],
                      width: 30,
                      height: 38,
                      child: Tooltip(
                        message: 'Pin ${i + 1}',
                        child: const Icon(
                          Icons.location_pin,
                          color: Color(0xFFFF748A),
                          size: 31,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: _MapInfoChip(
            icon: Icons.public_rounded,
            label: '${map.title} · ${_pins.length} pins',
          ),
        ),
        if (map.attribution != null && map.attribution!.trim().isNotEmpty)
          Positioned(
            left: 12,
            bottom: 10,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: _MapInfoChip(
                icon: Icons.info_outline_rounded,
                label: map.attribution!,
              ),
            ),
          ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            tooltip: 'Clear pins',
            onPressed: _pins.isEmpty ? null : () => setState(_pins.clear),
            child: const Icon(Icons.layers_clear_rounded),
          ),
        ),
      ],
    );
  }
}

class _MapInfoChip extends StatelessWidget {
  const _MapInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD101826),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFFB3C4FF)),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xFFB3C4FF)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.5,
                  color: Colors.white.withAlpha(155),
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.file_open_rounded, size: 16),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
