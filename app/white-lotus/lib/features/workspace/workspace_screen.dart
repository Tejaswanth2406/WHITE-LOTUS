import 'package:flutter/material.dart';

import '../../design_system/glass_panel.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key, required this.section});

  final String section;

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _privateMode = true;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: switch (widget.section) {
            'Browser' => _buildBrowser(),
            'Torrent' => _buildTorrent(),
            'VPN' => _buildVpn(),
            _ => _buildNotes(),
          },
        ),
      ),
    );
  }

  Widget _buildTorrent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          eyebrow: 'TRANSFER MANAGER',
          title: 'Torrent',
          subtitle: 'No torrent engine is connected. Nothing is downloading.',
        ),
        const SizedBox(height: 20),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFFFC58F),
                    size: 18,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Not connected',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'No torrent service is running. This concept page does not download or seed files.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: GlassPanel(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.downloading_rounded,
                    size: 30,
                    color: Color(0xFF9BAAFF),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Transfer queue is empty',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVpn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          eyebrow: 'CONNECTION PRIVACY',
          title: 'VPN',
          subtitle: 'A VPN integration can be added after the core local experience is ready.',
        ),
        const SizedBox(height: 22),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.vpn_lock_rounded,
                size: 30,
                color: Color(0xFFBFA6FF),
              ),
              const SizedBox(height: 14),
              const Text(
                'Not connected',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'No VPN provider or tunnel is configured.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withAlpha(145),
                ),
              ),
              const SizedBox(height: 14),
              const Chip(
                avatar: Icon(Icons.schedule_rounded, size: 14),
                label: Text('Planned feature', style: TextStyle(fontSize: 9)),
                backgroundColor: Color(0x2222FFFFFF),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          eyebrow: 'CAPTURE A THOUGHT',
          title: 'Notepad',
          subtitle: 'Quick notes stay on this device.',
        ),
        const SizedBox(height: 22),
        Expanded(
          child: GlassPanel(
            radius: 25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sticky_note_2_rounded, color: Color(0xFFB8B1FF)),
                    SizedBox(width: 9),
                    Text(
                      'New note draft',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Spacer(),
                    Icon(Icons.more_horiz_rounded),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    expands: true,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'Start writing… ideas, lists, reminders.',
                      hintStyle: TextStyle(color: Colors.white.withAlpha(100)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 14,
                      color: Colors.white.withAlpha(150),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Not saved yet',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withAlpha(150),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_noteController.text.length} characters',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withAlpha(120),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrowser() {
    final services = [
      (
        Icons.travel_explore_rounded,
        'Private browsing',
        'A focused browser workspace with privacy controls.',
        const Color(0xFF9FAAFF),
      ),
      (
        Icons.download_rounded,
        'Torrent transfers',
        'Manage peer-to-peer downloads in one place.',
        const Color(0xFF76DFCE),
      ),
      (
        Icons.block_rounded,
        'Built-in ad blocker',
        'Reduce distracting ads and trackers while browsing.',
        const Color(0xFFFFC08D),
      ),
      (
        Icons.vpn_lock_rounded,
        'VPN connection',
        'A secure connection service can be integrated here.',
        const Color(0xFFC4A5FF),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          eyebrow: 'A QUIETER INTERNET',
          title: 'Private browser',
          subtitle: 'Browser tools are shown as a product concept; network services are not connected yet.',
        ),
        const SizedBox(height: 22),
        GlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          radius: 16,
          child: Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF77DECE),
                size: 17,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search or enter a web address',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(120),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Toggle private mode (prototype)',
                onPressed: () => setState(() => _privateMode = !_privateMode),
                icon: Icon(
                  _privateMode ? Icons.shield_rounded : Icons.shield_outlined,
                  color: _privateMode
                      ? const Color(0xFF77DECE)
                      : Colors.white70,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: GridView.builder(
            itemCount: services.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 330,
              mainAxisExtent: 150,
              crossAxisSpacing: 13,
              mainAxisSpacing: 13,
            ),
            itemBuilder: (context, index) {
              final service = services[index];
              return GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(service.$1, color: service.$4),
                    const Spacer(),
                    Text(
                      service.$2,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      service.$3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.4,
                        color: Colors.white.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Color(0xFF9BAAFF),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(150)),
        ),
      ],
    );
  }
}
