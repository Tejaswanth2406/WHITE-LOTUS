import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class ElasticReelItem {
  const ElasticReelItem({required this.image, this.title});

  final ImageProvider image;
  final String? title;
}

class ElasticReel extends StatefulWidget {
  const ElasticReel({
    super.key,
    required this.items,
    this.height = 360,
    this.gap = 6,
    this.radius = 14,
    this.expandRatio = 9,
    this.spread = 1.6,
    this.falloff = 1.4,
    this.minHeightFactor = 0.78,
    this.stiffness = 260,
    this.dampingRatio = 0.55,
    this.sticky = true,
    this.initialIndex,
    this.onSelect,
    this.accentColor = Colors.white,
    this.titleStyle,
  });

  final List<ElasticReelItem> items;
  final double height;
  final double gap;
  final double radius;
  final double expandRatio;
  final double spread;
  final double falloff;
  final double minHeightFactor;
  final double stiffness;
  final double dampingRatio;
  final bool sticky;
  final int? initialIndex;
  final ValueChanged<int>? onSelect;
  final Color accentColor;
  final TextStyle? titleStyle;

  @override
  State<ElasticReel> createState() => _ElasticReelState();
}

class _ElasticReelState extends State<ElasticReel>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  List<double> _widthFactors = [];
  List<double> _velocities = [];
  int? _hovered;
  int? _selected;
  double _availableWidth = 0;

  int get _itemCount => widget.items.length;

  @override
  void initState() {
    super.initState();
    _selected = _validInitialIndex(widget);
    _resetSprings(snap: true);
    _ticker = createTicker(_tick);
    _kick();
  }

  @override
  void didUpdateWidget(covariant ElasticReel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != _itemCount ||
        oldWidget.initialIndex != widget.initialIndex) {
      _selected = _validInitialIndex(widget);
      _resetSprings(snap: true);
    }
    _kick();
  }

  int? _validInitialIndex(ElasticReel value) {
    if (value.items.isEmpty) return null;
    return (value.initialIndex ?? 0).clamp(0, value.items.length - 1).toInt();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  List<double> _targets() {
    final focus = _hovered ?? (widget.sticky ? _selected : null);
    return List.generate(_itemCount, (index) {
      if (focus == null) return 1;
      final distance = (index - focus).abs() / widget.spread;
      final influence = math
          .pow(math.max(0.0, 1 - distance), widget.falloff)
          .toDouble();
      return 1 + (widget.expandRatio - 1) * influence;
    });
  }

  void _resetSprings({required bool snap}) {
    final targets = _targets();
    _widthFactors = snap ? targets : List.filled(_itemCount, 1);
    _velocities = List.filled(_itemCount, 0);
  }

  void _kick() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6)
        .clamp(0.0, 1 / 20)
        .toDouble();
    _last = elapsed;
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final targets = _targets();
    final stiffness = widget.stiffness;
    final damping = 2 * widget.dampingRatio * math.sqrt(stiffness);
    final steps = math.max(1, (dt / (1 / 240)).ceil());
    final stepDuration = dt / steps;
    var moving = false;

    for (var index = 0; index < _itemCount; index++) {
      if (reducedMotion) {
        _widthFactors[index] = targets[index];
        _velocities[index] = 0;
        continue;
      }
      for (var step = 0; step < steps; step++) {
        final acceleration =
            -stiffness * (_widthFactors[index] - targets[index]) -
            damping * _velocities[index];
        _velocities[index] += acceleration * stepDuration;
        _widthFactors[index] += _velocities[index] * stepDuration;
      }
      if ((_widthFactors[index] - targets[index]).abs() > 0.002 ||
          _velocities[index].abs() > 0.01) {
        moving = true;
      } else {
        _widthFactors[index] = targets[index];
        _velocities[index] = 0;
      }
    }
    setState(() {});
    if (!moving) _ticker.stop();
  }

  List<double> _widths() {
    final sum = _widthFactors.fold<double>(0, (total, value) => total + value);
    return [
      for (final factor in _widthFactors)
        _availableWidth * factor / math.max(sum, 0.0001),
    ];
  }

  int? _indexAt(double x) {
    final widths = _widths();
    var left = 0.0;
    for (var index = 0; index < widths.length; index++) {
      final right =
          left + widths[index] + (index < widths.length - 1 ? widget.gap : 0);
      if (x < right) return index;
      left = right;
    }
    return widths.isEmpty ? null : widths.length - 1;
  }

  void _focusAt(double x) {
    final index = _indexAt(x);
    if (index == _hovered) return;
    _hovered = index;
    if (index != null) HapticFeedback.selectionClick();
    _kick();
  }

  void _select(int? index) {
    if (index == null) return;
    _selected = index;
    widget.onSelect?.call(index);
    _kick();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 640.0;
        _availableWidth = math.max(
          0.0,
          maxWidth - widget.gap * (_itemCount - 1),
        );
        final widths = _widths();
        final fullWidth =
            _availableWidth *
            widget.expandRatio /
            (widget.expandRatio + math.max(_itemCount - 1, 0));
        final focus = _hovered ?? (widget.sticky ? _selected : null);

        return MouseRegion(
          onHover: (event) => _focusAt(event.localPosition.dx),
          onExit: (_) {
            _hovered = null;
            _kick();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _select(_indexAt(details.localPosition.dx)),
            onHorizontalDragStart: (details) =>
                _focusAt(details.localPosition.dx),
            onHorizontalDragUpdate: (details) =>
                _focusAt(details.localPosition.dx),
            onHorizontalDragEnd: (_) {
              _select(_hovered);
              _hovered = null;
              _kick();
            },
            child: SizedBox(
              width: maxWidth,
              height: widget.height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < _itemCount; index++) ...[
                    if (index > 0) SizedBox(width: widget.gap),
                    _buildSlice(
                      index,
                      widths[index],
                      fullWidth,
                      index == focus,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlice(int index, double width, double fullWidth, bool focused) {
    final item = widget.items[index];
    final expansion =
        ((_widthFactors[index] - 1) / math.max(widget.expandRatio - 1, 0.0001))
            .clamp(0.0, 1.0)
            .toDouble();
    final height =
        widget.height *
        (widget.minHeightFactor + (1 - widget.minHeightFactor) * expansion);
    final imageWidth = math.max(width, fullWidth * 0.85);

    return Semantics(
      button: true,
      label: item.title ?? 'Image ${index + 1}',
      selected: focused,
      child: SizedBox(
        width: math.max(width, 0),
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.35 * expansion),
                blurRadius: 30 * expansion,
                offset: Offset(0, 14 * expansion),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                OverflowBox(
                  minWidth: imageWidth,
                  maxWidth: imageWidth,
                  alignment: Alignment.center,
                  child: Image(
                    image: item.image,
                    width: imageWidth,
                    height: height,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
                Opacity(
                  opacity: (1 - expansion) * 0.35,
                  child: const ColoredBox(color: Colors.black),
                ),
                if (item.title != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: ((expansion - 0.55) / 0.45)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 28, 14, 14),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0xB3000000)],
                          ),
                        ),
                        child: Text(
                          item.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              widget.titleStyle ??
                              TextStyle(
                                color: widget.accentColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
}
