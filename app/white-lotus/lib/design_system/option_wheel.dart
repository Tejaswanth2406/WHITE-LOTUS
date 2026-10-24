import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

enum WheelSide { left, right }

class OptionWheel extends StatefulWidget {
  const OptionWheel({
    super.key,
    required this.items,
    required this.defaultSelected,
    this.onChanged,
    this.onTick,
    this.haptics = true,
    this.textColor = const Color(0xFFA6A6A6),
    this.activeColor = Colors.white,
    this.side = WheelSide.left,
    this.fontSize = 3,
    this.spacing = 1.4,
    this.curve = 1,
    this.tilt = 6,
    this.blur = 2,
    this.fade = 0.25,
    this.minOpacity = 0.05,
    this.smoothingMs = 200,
    this.inset = 80,
    this.loop = false,
    this.draggable = true,
    this.fontFamily,
  });

  final List<String> items;
  final int defaultSelected;
  final void Function(int index, String item)? onChanged;
  final VoidCallback? onTick;
  final bool haptics;
  final Color textColor;
  final Color activeColor;
  final WheelSide side;
  final double fontSize;
  final double spacing;
  final double curve;
  final double tilt;
  final double blur;
  final double fade;
  final double minOpacity;
  final double smoothingMs;
  final double inset;
  final bool loop;
  final bool draggable;
  final String? fontFamily;

  @override
  State<OptionWheel> createState() => _OptionWheelState();
}

class _OptionWheelState extends State<OptionWheel>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  late double _position;
  late double _target;
  late int _selected;
  Timer? _wheelTimer;
  bool _dragging = false;
  bool _moved = false;
  double _dragStartY = 0;
  double _dragStartTarget = 0;
  final FocusNode _node = FocusNode();
  int _lastTickMs = 0;

  double get _fontPx => widget.fontSize * 16;
  double get _rowHeight => math.max(_fontPx * widget.spacing, 1);
  int get _itemCount => widget.items.length;

  @override
  void initState() {
    super.initState();
    final selection = _initialSelection(widget);
    _position = _target = selection.toDouble();
    _selected = selection;
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(covariant OptionWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.defaultSelected != widget.defaultSelected) {
      final selection = _initialSelection(widget);
      _position = _target = selection.toDouble();
      _selected = selection;
      _ticker.stop();
    }
  }

  int _initialSelection(OptionWheel value) {
    if (value.items.isEmpty) return 0;
    return value.defaultSelected.clamp(0, value.items.length - 1).toInt();
  }

  @override
  void dispose() {
    _wheelTimer?.cancel();
    _ticker.dispose();
    _node.dispose();
    super.dispose();
  }

  void _start() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6)
        .clamp(0.0, 0.05)
        .toDouble();
    _last = elapsed;
    final tau = math.max(widget.smoothingMs, 1) / 1000;
    final factor = 1 - math.exp(-dt / tau);
    var next = _position + (_target - _position) * factor;
    final settled = (_target - next).abs() < 0.001;
    if (settled) next = _target;
    setState(() => _position = next);
    if (settled) _ticker.stop();
  }

  void _applyTarget(double value, {required bool snap}) {
    if (_itemCount == 0) return;
    var next = value;
    if (!widget.loop) {
      next = next.clamp(0.0, math.max(_itemCount - 1, 0).toDouble());
    }
    if (snap) next = next.roundToDouble();
    _target = next;
    final index = ((next.round() % _itemCount) + _itemCount) % _itemCount;
    if (index != _selected) {
      setState(() => _selected = index);
      widget.onChanged?.call(index, widget.items[index]);
      _playTick();
    }
    _start();
  }

  void _playTick() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTickMs < 70) return;
    _lastTickMs = now;
    if (widget.haptics) HapticFeedback.selectionClick();
    widget.onTick?.call();
  }

  void _onWheel(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      final scroll = resolved as PointerScrollEvent;
      final step = (scroll.scrollDelta.dy / _rowHeight)
          .clamp(-1.0, 1.0)
          .toDouble();
      _applyTarget(_target + step, snap: false);
      _wheelTimer?.cancel();
      _wheelTimer = Timer(
        const Duration(milliseconds: 140),
        () => _applyTarget(_target, snap: true),
      );
    });
  }

  void _onItemTap(int index) {
    if (_moved || _itemCount == 0) return;
    final currentIndex = ((_target % _itemCount) + _itemCount) % _itemCount;
    var delta = index - currentIndex;
    if (widget.loop && _itemCount > 1) {
      if (delta > _itemCount / 2) {
        delta -= _itemCount;
      } else if (delta < -_itemCount / 2) {
        delta += _itemCount;
      }
    }
    _applyTarget(_target + delta, snap: true);
  }

  @override
  Widget build(BuildContext context) {
    final mirror = widget.side == WheelSide.right ? -1.0 : 1.0;
    final tiltRadians = widget.tilt * math.pi / 180;
    final radius = tiltRadians > 0.0005 ? _rowHeight / tiltRadians : 0.0;
    final alignLeft = widget.side == WheelSide.left;
    final children = <Widget>[];

    for (var index = 0; index < _itemCount; index++) {
      var delta = index - _position;
      if (widget.loop && _itemCount > 1) {
        delta = ((delta % _itemCount) + _itemCount) % _itemCount;
        if (delta > _itemCount / 2) delta -= _itemCount;
      }
      final distance = delta.abs();
      var x = 0.0;
      var y = delta * _rowHeight;
      var rotation = 0.0;
      if (radius > 0) {
        final angle = (delta * tiltRadians)
            .clamp(-math.pi / 2, math.pi / 2)
            .toDouble();
        y = radius * math.sin(angle);
        x = -mirror * radius * (1 - math.cos(angle)) * widget.curve;
        rotation = mirror * angle;
      }
      final opacity = math
          .max(widget.minOpacity, 1 - distance * widget.fade)
          .clamp(0.0, 1.0)
          .toDouble();
      final blurPx = widget.blur > 0 ? distance * widget.blur : 0.0;
      final blend = math.max(0.0, 1 - math.min(distance, 1.0)).toDouble();
      Widget label = Text(
        widget.items[index],
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: Color.lerp(widget.textColor, widget.activeColor, blend),
          fontSize: _fontPx,
          height: 1,
          fontWeight: index == _selected ? FontWeight.w500 : FontWeight.w200,
          fontFamily: widget.fontFamily,
        ),
      );
      if (blurPx > 0.05) {
        label = ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: blurPx,
            sigmaY: blurPx,
            tileMode: TileMode.decal,
          ),
          child: label,
        );
      }
      children.add(
        Positioned.fill(
          key: ValueKey('$index-${widget.items[index]}'),
          child: Align(
            alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(
                left: alignLeft ? widget.inset : 0,
                right: alignLeft ? 0 : widget.inset,
              ),
              child: Transform.translate(
                offset: Offset(x, y),
                child: Transform.rotate(
                  angle: rotation,
                  alignment: alignLeft
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Opacity(
                    opacity: opacity,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _onItemTap(index),
                      child: Semantics(
                        selected: index == _selected,
                        button: true,
                        child: label,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Focus(
      focusNode: _node,
      onKeyEvent: (node, event) {
        if (event is KeyUpEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        final delta =
            key == LogicalKeyboardKey.arrowUp ||
                key == LogicalKeyboardKey.arrowLeft
            ? -1.0
            : key == LogicalKeyboardKey.arrowDown ||
                  key == LogicalKeyboardKey.arrowRight
            ? 1.0
            : null;
        if (delta == null) return KeyEventResult.ignored;
        _applyTarget(_target.roundToDouble() + delta, snap: true);
        return KeyEventResult.handled;
      },
      child: Listener(
        onPointerSignal: _onWheel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _node.requestFocus(),
          onVerticalDragStart: widget.draggable
              ? (details) {
                  _dragStartY = details.globalPosition.dy;
                  _dragStartTarget = _target;
                  _moved = false;
                  setState(() => _dragging = true);
                }
              : null,
          onVerticalDragUpdate: widget.draggable
              ? (details) {
                  final dy = details.globalPosition.dy - _dragStartY;
                  if (dy.abs() > 4) _moved = true;
                  if (_moved) {
                    _applyTarget(
                      _dragStartTarget - dy / _rowHeight,
                      snap: false,
                    );
                  }
                }
              : null,
          onVerticalDragEnd: widget.draggable
              ? (_) {
                  setState(() => _dragging = false);
                  if (_moved) _applyTarget(_target, snap: true);
                  Future.delayed(
                    const Duration(milliseconds: 50),
                    () => _moved = false,
                  );
                }
              : null,
          child: MouseRegion(
            cursor: _dragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.grab,
            child: ClipRect(
              child: SizedBox.expand(child: Stack(children: children)),
            ),
          ),
        ),
      ),
    );
  }
}
