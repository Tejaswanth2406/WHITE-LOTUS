import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum GridDirection { alternate, left, right }

class GridMotion extends StatefulWidget {
  const GridMotion({
    super.key,
    required this.items,
    this.rows = 4,
    this.aspectRatio = 1.33,
    this.gap = 12,
    this.radius = 14,
    this.speed = 24,
    this.direction = GridDirection.alternate,
    this.parallax = .5,
    this.dim = .2,
    this.tileColor = const Color(0xFF1B1922),
    this.borderColor = const Color(0x24FFFFFF),
    this.grayscale = false,
  }) : assert(rows > 0),
       assert(aspectRatio > 0),
       assert(speed >= 0);

  final List<ImageProvider> items;
  final int rows;
  final double aspectRatio;
  final double gap;
  final double radius;
  final double speed;
  final GridDirection direction;
  final double parallax;
  final double dim;
  final Color tileColor;
  final Color borderColor;
  final bool grayscale;

  @override
  State<GridMotion> createState() => _GridMotionState();
}

class _GridMotionState extends State<GridMotion>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  List<double> _offsets = const [];
  Offset _pointer = Offset.zero;
  bool _pointerActive = false;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setReducedMotion(MediaQuery.disableAnimationsOf(context));
  }

  @override
  void didUpdateWidget(covariant GridMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      _offsets = List<double>.filled(widget.rows, 0);
    }
    if (oldWidget.items.isEmpty && widget.items.isNotEmpty) _start();
  }

  void _setReducedMotion(bool reduced) {
    if (_reducedMotion == reduced) {
      if (!reduced) _start();
      return;
    }
    _reducedMotion = reduced;
    if (reduced) {
      _ticker.stop();
      _last = Duration.zero;
    } else {
      _start();
    }
  }

  void _start() {
    if (!_reducedMotion && widget.items.isNotEmpty && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6)
        .clamp(0.0, .05)
        .toDouble();
    _last = elapsed;
    if (dt == 0 || widget.items.isEmpty) return;
    setState(() {
      for (var row = 0; row < _offsets.length; row++) {
        final direction = switch (widget.direction) {
          GridDirection.left => -1.0,
          GridDirection.right => 1.0,
          GridDirection.alternate => row.isEven ? -1.0 : 1.0,
        };
        _offsets[row] += widget.speed * direction * dt;
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    if (_offsets.length != widget.rows) {
      _offsets = List<double>.filled(widget.rows, 0);
      _start();
    }
    final tileCount = widget.items.length;
    final dim = widget.dim.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          if (!width.isFinite ||
              !height.isFinite ||
              width <= 0 ||
              height <= 0) {
            return const SizedBox.shrink();
          }
          final gap = math.max(0.0, widget.gap);
          final tileHeight = (height - gap * (widget.rows - 1)) / widget.rows;
          if (tileHeight <= 0) return const SizedBox.shrink();
          final tileWidth = tileHeight * widget.aspectRatio;
          final step = tileWidth + gap;
          final cycleWidth = step * tileCount;
          final copies =
              ((width + cycleWidth + step * 2) / cycleWidth).ceil() + 1;

          return MouseRegion(
            onHover: (event) {
              _pointer = event.localPosition;
              _pointerActive = true;
            },
            onExit: (_) => _pointerActive = false,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (var row = 0; row < widget.rows; row++)
                  Positioned(
                    left:
                        -cycleWidth +
                        (_offsets[row] % cycleWidth) +
                        (_pointerActive
                            ? (_pointer.dx / width - .5) *
                                  widget.parallax *
                                  tileWidth *
                                  (row.isEven ? -1 : 1)
                            : 0),
                    top: row * (tileHeight + gap),
                    height: tileHeight,
                    child: Row(
                      children: [
                        for (var index = 0; index < copies * tileCount; index++)
                          Padding(
                            padding: EdgeInsets.only(right: gap),
                            child: _tile(
                              widget.items[(index + row) % tileCount],
                              tileWidth,
                              tileHeight,
                              dim,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tile(ImageProvider image, double width, double height, double dim) {
    Widget child = Image(
      image: image,
      fit: BoxFit.cover,
      width: width,
      height: height,
      gaplessPlayback: true,
    );
    if (widget.grayscale) {
      child = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          .2126,
          .7152,
          .0722,
          0,
          0,
          .2126,
          .7152,
          .0722,
          0,
          0,
          .2126,
          .7152,
          .0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: child,
      );
    }
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.tileColor,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: widget.borderColor),
      ),
      foregroundDecoration: BoxDecoration(
        color: Colors.black.withValues(alpha: dim),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      child: child,
    );
  }
}
