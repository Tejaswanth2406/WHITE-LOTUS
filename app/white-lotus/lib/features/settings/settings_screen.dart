import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../../design_system/elastic_slider.dart';
import '../../design_system/glass_panel.dart';
import '../../design_system/option_wheel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.selectedWallpaperIndex,
    required this.selectedWallpaperImage,
    required this.wallpaperDim,
    required this.onSelectWallpaper,
    required this.onSelectWallpaperImage,
    required this.onWallpaperDimChanged,
  });

  final int selectedWallpaperIndex;
  final Uint8List? selectedWallpaperImage;
  final double wallpaperDim;
  final ValueChanged<int> onSelectWallpaper;
  final ValueChanged<Uint8List> onSelectWallpaperImage;
  final ValueChanged<double> onWallpaperDimChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPickingWallpaper = false;

  Future<void> _pickWallpaper() async {
    setState(() => _isPickingWallpaper = true);
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Choose a wallpaper image',
        type: FileType.image,
      );
      if (file == null || !mounted) return;

      final image = await file.readAsBytes();
      if (mounted) widget.onSelectWallpaperImage(image);
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message ?? 'The image picker could not be opened.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingWallpaper = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personalize your space',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Make White Lotus feel like yours.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withAlpha(150),
                ),
              ),
              const SizedBox(height: 22),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Choose a liquid-glass colorway for your workspace.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withAlpha(145),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: OptionWheel(
                        items: widget.selectedWallpaperIndex < 0
                            ? const [
                                'Custom image',
                                'Black',
                                'Burgundy',
                                'Navy blue',
                              ]
                            : const ['Black', 'Burgundy', 'Navy blue'],
                        defaultSelected: widget.selectedWallpaperIndex < 0
                            ? 0
                            : widget.selectedWallpaperIndex.clamp(0, 2).toInt(),
                        onChanged: (index, _) {
                          final wallpaperIndex =
                              index -
                              (widget.selectedWallpaperIndex < 0 ? 1 : 0);
                          if (wallpaperIndex >= 0) {
                            widget.onSelectWallpaper(wallpaperIndex);
                          }
                        },
                        fontSize: 1.25,
                        spacing: 1.55,
                        tilt: 8,
                        blur: 0.5,
                        fade: 0.3,
                        inset: 18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0x24FFFFFF)),
                    const SizedBox(height: 12),
                    const Text(
                      'Use an image',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Choose any image saved on your device, including one '
                      'from Downloads.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withAlpha(145),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 96,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(8),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: Colors.white.withAlpha(20),
                              ),
                            ),
                            child: widget.selectedWallpaperImage == null
                                ? const Center(
                                    child: Text(
                                      'No image wallpaper selected',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF9AA6BB),
                                      ),
                                    ),
                                  )
                                : Image.memory(
                                    widget.selectedWallpaperImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _isPickingWallpaper
                              ? null
                              : _pickWallpaper,
                          icon: _isPickingWallpaper
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_photo_alternate_rounded),
                          label: Text(
                            _isPickingWallpaper ? 'Opening…' : 'Choose image',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Wallpaper dimming',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adjust contrast over your custom wallpaper.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withAlpha(145),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_outlined, size: 17),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElasticSlider(
                            value: widget.wallpaperDim,
                            startingValue: 0,
                            maxValue: 80,
                            length: 260,
                            leftIcon: const SizedBox.shrink(),
                            rightIcon: const Icon(
                              Icons.contrast_rounded,
                              size: 17,
                            ),
                            valuePosition: ElasticValuePosition.none,
                            formatValue: (value) => '${value.round()}%',
                            rangeColor: const Color(0xFFA9B9FF),
                            trackColor: Colors.white.withAlpha(45),
                            semanticLabel: 'Wallpaper dimming',
                            onChanged: widget.onWallpaperDimChanged,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 38,
                          child: Text(
                            '${widget.wallpaperDim.round()}%',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const GlassPanel(
                child: Column(
                  children: [
                    _SettingRow(
                      icon: Icons.cloud_off_rounded,
                      title: 'Local-first storage',
                      value: 'Active',
                    ),
                    Divider(height: 25, color: Color(0x24FFFFFF)),
                    _SettingRow(
                      icon: Icons.sync_rounded,
                      title: 'Cloud sync',
                      value: 'Not connected',
                    ),
                    Divider(height: 25, color: Color(0x24FFFFFF)),
                    _SettingRow(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy',
                      value: 'On-device by default',
                    ),
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

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF9BAAFF)),
        const SizedBox(width: 11),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 12))),
        Text(
          value,
          style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(145)),
        ),
      ],
    );
  }
}
