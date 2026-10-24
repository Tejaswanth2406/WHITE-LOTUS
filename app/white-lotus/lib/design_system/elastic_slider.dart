import 'package:flutter/material.dart';

enum ElasticValuePosition { top, bubble, none }

class ElasticSlider extends StatefulWidget {
  const ElasticSlider({
    super.key,
    required this.onChanged,
    this.value,
    this.defaultValue = 50,
    this.startingValue = 0,
    this.maxValue = 100,
    this.length = 192,
    this.leftIcon = const Icon(Icons.volume_mute_rounded, size: 20),
    this.rightIcon = const Icon(Icons.volume_up_rounded, size: 20),
    this.valuePosition = ElasticValuePosition.top,
    this.formatValue,
    this.thickness = 6,
    this.activeThickness = 12,
    this.trackColor,
    this.rangeColor,
    this.thumbColor = Colors.white,
    this.enabled = true,
    this.semanticLabel = 'Slider',
  }) : assert(maxValue >= startingValue);

  final double? value;
  final double defaultValue;
  final double startingValue;
  final double maxValue;
  final double length;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final ElasticValuePosition valuePosition;
  final String Function(double)? formatValue;
  final double thickness;
  final double activeThickness;
  final Color? trackColor;
  final Color? rangeColor;
  final Color thumbColor;
  final bool enabled;
  final String semanticLabel;
  final ValueChanged<double> onChanged;

  @override
  State<ElasticSlider> createState() => _ElasticSliderState();
}

class _ElasticSliderState extends State<ElasticSlider> {
  late double _value;
  bool _active = false;

  double get _current => (widget.value ?? _value)
      .clamp(widget.startingValue, widget.maxValue)
      .toDouble();

  String _label() =>
      widget.formatValue?.call(_current) ?? _current.round().toString();

  @override
  void initState() {
    super.initState();
    _value = widget.defaultValue
        .clamp(widget.startingValue, widget.maxValue)
        .toDouble();
  }

  @override
  void didUpdateWidget(covariant ElasticSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startingValue != widget.startingValue ||
        oldWidget.maxValue != widget.maxValue) {
      _value = _value.clamp(widget.startingValue, widget.maxValue).toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final track = widget.trackColor ?? colors.onSurface.withAlpha(46);
    final active = widget.rangeColor ?? colors.onSurface;
    final displayValue = widget.valuePosition == ElasticValuePosition.none
        ? const SizedBox.shrink()
        : Text(
            _label(),
            style: TextStyle(
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: colors.onSurface.withAlpha(180),
            ),
          );
    final slider = MouseRegion(
      onEnter: (_) => setState(() => _active = true),
      onExit: (_) => setState(() => _active = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: widget.activeThickness + 26,
        alignment: Alignment.center,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: _active ? widget.activeThickness : widget.thickness,
            activeTrackColor: active,
            inactiveTrackColor: track,
            thumbColor: widget.thumbColor,
            overlayColor: active.withAlpha(30),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 7,
              elevation: 0,
              pressedElevation: 1,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            min: widget.startingValue,
            max: widget.maxValue,
            value: _current,
            onChanged: widget.enabled
                ? (value) {
                    setState(() => _value = value);
                    widget.onChanged(value);
                  }
                : null,
            semanticFormatterCallback: (_) => _label(),
          ),
        ),
      ),
    );
    final content = Row(
      children: [
        if (widget.leftIcon != null) ...[
          IconTheme(
            data: IconThemeData(color: colors.onSurface.withAlpha(175)),
            child: widget.leftIcon!,
          ),
          const SizedBox(width: 10),
        ],
        Expanded(child: slider),
        if (widget.rightIcon != null) ...[
          const SizedBox(width: 10),
          IconTheme(
            data: IconThemeData(color: colors.onSurface.withAlpha(175)),
            child: widget.rightIcon!,
          ),
        ],
      ],
    );

    return Semantics(
      label: widget.semanticLabel,
      value: _label(),
      slider: true,
      child: SizedBox(
        width: widget.length,
        child: widget.valuePosition == ElasticValuePosition.top
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [displayValue, content],
              )
            : content,
      ),
    );
  }
}
