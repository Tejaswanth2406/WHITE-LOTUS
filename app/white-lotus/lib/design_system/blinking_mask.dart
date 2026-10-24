import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

const List<Offset> _leftEyePoints = [
  Offset(.3152, .6988),
  Offset(.2908, .6990),
  Offset(.2867, .6977),
  Offset(.2812, .6977),
  Offset(.2731, .6960),
  Offset(.2486, .6838),
  Offset(.2391, .6769),
  Offset(.2364, .6732),
  Offset(.2310, .6691),
  Offset(.2235, .6617),
  Offset(.2215, .6584),
  Offset(.2185, .6562),
  Offset(.2160, .6516),
  Offset(.2092, .6446),
  Offset(.2061, .6399),
  Offset(.2001, .6264),
  Offset(.1898, .6087),
  Offset(.1803, .5815),
  Offset(.1746, .5557),
  Offset(.1726, .5421),
  Offset(.1732, .5380),
  Offset(.1719, .5340),
  Offset(.1719, .5272),
  Offset(.1705, .5231),
  Offset(.1705, .4810),
  Offset(.1719, .4769),
  Offset(.1719, .4660),
  Offset(.1732, .4620),
  Offset(.1733, .4443),
  Offset(.1746, .4402),
  Offset(.1762, .4253),
  Offset(.1879, .3804),
  Offset(.1898, .3696),
  Offset(.1997, .3449),
  Offset(.2011, .3448),
  Offset(.2296, .3583),
  Offset(.2337, .3618),
  Offset(.2527, .3719),
  Offset(.2704, .3828),
  Offset(.3158, .4144),
  Offset(.3310, .4280),
  Offset(.3410, .4355),
  Offset(.3492, .4436),
  Offset(.3533, .4463),
  Offset(.3743, .4674),
  Offset(.3838, .4796),
  Offset(.3995, .4967),
  Offset(.4229, .5312),
  Offset(.4235, .5340),
  Offset(.4311, .5448),
  Offset(.4216, .5802),
  Offset(.4134, .6019),
  Offset(.3999, .6304),
  Offset(.3859, .6527),
  Offset(.3723, .6691),
  Offset(.3492, .6865),
  Offset(.3342, .6947),
];

const List<Offset> _rightEyePoints = [
  Offset(.7160, .7001),
  Offset(.6970, .7004),
  Offset(.6929, .6991),
  Offset(.6780, .6977),
  Offset(.6671, .6947),
  Offset(.6590, .6906),
  Offset(.6495, .6830),
  Offset(.6408, .6780),
  Offset(.6257, .6630),
  Offset(.6124, .6467),
  Offset(.6042, .6332),
  Offset(.5934, .6114),
  Offset(.5811, .5802),
  Offset(.5730, .5476),
  Offset(.5798, .5340),
  Offset(.5901, .5204),
  Offset(.5974, .5082),
  Offset(.6087, .4927),
  Offset(.6284, .4688),
  Offset(.6603, .4382),
  Offset(.6704, .4307),
  Offset(.6842, .4185),
  Offset(.7120, .3999),
  Offset(.7215, .3923),
  Offset(.7486, .3768),
  Offset(.7595, .3692),
  Offset(.7622, .3686),
  Offset(.7717, .3624),
  Offset(.7867, .3550),
  Offset(.7908, .3515),
  Offset(.8043, .3458),
  Offset(.8059, .3465),
  Offset(.8075, .3505),
  Offset(.8107, .3655),
  Offset(.8143, .3750),
  Offset(.8203, .3995),
  Offset(.8224, .4049),
  Offset(.8254, .4198),
  Offset(.8281, .4443),
  Offset(.8295, .4484),
  Offset(.8309, .4674),
  Offset(.8322, .4715),
  Offset(.8322, .4823),
  Offset(.8335, .4864),
  Offset(.8335, .5258),
  Offset(.8322, .5299),
  Offset(.8322, .5367),
  Offset(.8254, .5707),
  Offset(.8251, .5761),
  Offset(.8197, .5951),
  Offset(.8107, .6128),
  Offset(.8088, .6196),
  Offset(.8034, .6304),
  Offset(.7908, .6500),
  Offset(.7751, .6685),
  Offset(.7682, .6753),
  Offset(.7568, .6838),
  Offset(.7473, .6885),
  Offset(.7378, .6947),
  Offset(.7296, .6974),
];

class BlinkingMask extends StatefulWidget {
  const BlinkingMask({
    super.key,
    required this.image,
    this.size = 300,
    this.lidColor = Colors.black,
    this.minPause = const Duration(milliseconds: 1800),
    this.maxPause = const Duration(milliseconds: 4200),
    this.closeDuration = const Duration(milliseconds: 80),
    this.openDuration = const Duration(milliseconds: 130),
    this.doubleBlinkChance = .2,
  }) : assert(doubleBlinkChance >= 0 && doubleBlinkChance <= 1);

  final ImageProvider image;
  final double size;
  final Color lidColor;
  final Duration minPause;
  final Duration maxPause;
  final Duration closeDuration;
  final Duration openDuration;
  final double doubleBlinkChance;

  @override
  State<BlinkingMask> createState() => _BlinkingMaskState();
}

class _BlinkingMaskState extends State<BlinkingMask>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random();
  Timer? _timer;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    if (widget.minPause.isNegative || widget.maxPause < widget.minPause) {
      throw ArgumentError(
        'Blink pause range must be non-negative and ordered.',
      );
    }
    _controller = AnimationController(
      vsync: this,
      duration: widget.closeDuration,
      reverseDuration: widget.openDuration,
    );
  }

  void _schedule() {
    if (_timer != null || !mounted || _reduceMotion) return;
    final minMs = widget.minPause.inMilliseconds;
    final pauseRange = widget.maxPause.inMilliseconds - minMs + 1;
    _timer = Timer(
      Duration(milliseconds: minMs + _random.nextInt(pauseRange)),
      () async {
        _timer = null;
        await _blink();
        if (!mounted || _reduceMotion) return;
        if (_random.nextDouble() < widget.doubleBlinkChance) {
          await Future<void>.delayed(const Duration(milliseconds: 110));
          if (!mounted || _reduceMotion) return;
          await _blink();
        }
        _schedule();
      },
    );
  }

  Future<void> _blink() async {
    try {
      await _controller.forward(from: 0).orCancel;
      await _controller.reverse().orCancel;
    } on TickerCanceled {
      // Disposing this widget cancels an in-progress blink.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion) {
      _timer?.cancel();
      _timer = null;
      _controller.value = 0;
    } else {
      _schedule();
    }
  }

  @override
  void didUpdateWidget(covariant BlinkingMask oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minPause != widget.minPause ||
        oldWidget.maxPause != widget.maxPause) {
      _timer?.cancel();
      _timer = null;
      _schedule();
    }
    if (oldWidget.closeDuration != widget.closeDuration) {
      _controller.duration = widget.closeDuration;
    }
    if (oldWidget.openDuration != widget.openDuration) {
      _controller.reverseDuration = widget.openDuration;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: widget.image, fit: BoxFit.fill),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => CustomPaint(
              painter: _LidPainter(
                Curves.easeInOut.transform(_controller.value),
                widget.lidColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LidPainter extends CustomPainter {
  const _LidPainter(this.amount, this.color);

  final double amount;
  final Color color;

  Path _eyePath(List<Offset> points, Size size) {
    final path = Path()
      ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (amount <= .001) return;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    for (final points in [_leftEyePoints, _rightEyePoints]) {
      final eye = _eyePath(points, size);
      final bounds = eye.getBounds();
      final reach = bounds.height / 2 * amount;
      final lids = [
        Rect.fromLTRB(
          bounds.left,
          bounds.top,
          bounds.right,
          bounds.top + reach,
        ),
        Rect.fromLTRB(
          bounds.left,
          bounds.bottom - reach,
          bounds.right,
          bounds.bottom,
        ),
      ];
      for (final lid in lids) {
        canvas
          ..save()
          ..clipPath(eye)
          ..clipRect(lid)
          ..drawPath(eye, paint)
          ..restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LidPainter oldDelegate) =>
      oldDelegate.amount != amount || oldDelegate.color != color;
}
