import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class Responsive {
  final BuildContext context;

  Responsive(this.context);

  Size get size => MediaQuery.sizeOf(context);
  double get width => size.width;
  double get height => size.height;
  double get shortestSide => math.min(width, height);

  bool get isCompact => width < 360;
  bool get isTablet => width >= 700;

  double scale(
    double value, {
    double minScale = 0.85,
    double maxScale = 1.30,
  }) {
    final ratio = (shortestSide / 390).clamp(minScale, maxScale);
    return value * ratio;
  }

  EdgeInsets pagePadding({
    double horizontal = 20,
    double top = 8,
    double bottom = 24,
  }) {
    return EdgeInsets.fromLTRB(
      scale(horizontal, minScale: 0.80, maxScale: 1.40),
      scale(top, minScale: 0.80, maxScale: 1.40),
      scale(horizontal, minScale: 0.80, maxScale: 1.40),
      scale(bottom, minScale: 0.80, maxScale: 1.50),
    );
  }
}
