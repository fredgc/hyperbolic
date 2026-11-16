import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../objects/objects.dart';
import '../transform.dart';
import 'scene_view.dart';

/// CustomPainter rendering the Poincaré disk boundary, hyperbolic lines/segments,
/// hyperbolic circles, points, labels, and selection highlights.
class DiskPainter extends CustomPainter {
  final SceneView scene;

  DiskPainter(this.scene, {super.repaint});

  @override
  void paint(Canvas canvas, Size size) {
    scene.transform.size = size;
    final transform = scene.transform;
    final screenCenter = transform.screenCenter;
    final screenRadius = transform.screenRadius;

    if (screenRadius <= 0.0) return;

    // Outer canvas background
    final canvasBgPaint = Paint()
      ..color = scene.settings.theme.scheme.surface
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      canvasBgPaint,
    );

    // 1. Background inside Poincaré Disk
    final diskBgPaint = Paint()
      ..color = scene.settings.backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(screenCenter, screenRadius, diskBgPaint);

    // Subtle grid/axes if enabled
    if (scene.showAxes.value) {
      _drawAxes(canvas, transform);
    }

    // Clip all hyperbolic geometry to the Poincaré Disk boundary
    canvas.save();
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: screenCenter, radius: screenRadius));
    canvas.clipPath(clipPath);

    // 2. Render Hyperbolic Circles
    for (final obj in scene.data.objects.whereType<CircleObject>()) {
      if (!obj.visible) continue;
      _drawCircle(canvas, transform, obj, isSelected: obj == scene.selected);
    }

    // 3. Render Hyperbolic Lines / Segments / Rays
    for (final obj in scene.data.objects.whereType<LineObject>()) {
      if (!obj.visible) continue;
      _drawLine(canvas, transform, obj, isSelected: obj == scene.selected);
    }

    // 4. Render Active Tool Previews
    _drawToolPreview(canvas, transform);

    // 5. Render Hyperbolic Points
    for (final obj in scene.data.objects.whereType<PointObject>()) {
      if (!obj.visible) continue;
      _drawPoint(
        canvas,
        transform,
        obj,
        isSelected: obj == scene.selected,
        isHovered: obj == scene.hoveredObject,
      );
    }

    canvas.restore();

    // 6. Poincaré Boundary Circle Outline
    final boundaryPaint = Paint()
      ..color = scene.settings.theme.scheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(screenCenter, screenRadius, boundaryPaint);
  }

  void _drawAxes(Canvas canvas, CoordinateTransform transform) {
    final axisPaint = Paint()
      ..color = scene.settings.theme.scheme.onSurface.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Origin in view coordinates
    final originView = transform.diskToView(const HyperbolicPoint.origin());
    final originScreen = transform.viewToScreen(originView);

    // Center crosshairs
    canvas.drawLine(
      Offset(originScreen.dx - 12, originScreen.dy),
      Offset(originScreen.dx + 12, originScreen.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(originScreen.dx, originScreen.dy - 12),
      Offset(originScreen.dx, originScreen.dy + 12),
      axisPaint,
    );
  }

  void _drawCircle(
    Canvas canvas,
    CoordinateTransform transform,
    CircleObject obj, {
    required bool isSelected,
  }) {
    if (obj.circle == null) return;
    final circle = obj.circle!;

    // Transform hyperbolic center under current Mobius view isometry:
    final centerView = transform.diskToView(circle.hyperbolicCenter);
    final double rho = circle.hyperbolicRadius;
    final double t = tanh(rho / 2.0);
    final double pSq = centerView.magnitudeSquared;
    final double denom = 1.0 - pSq * t * t;
    if (denom.abs() < 1e-12) return;

    final factorC = (1.0 - t * t) / denom;
    final centerEuclidView = centerView.scale(factorC);
    final double radiusEuclidView = ((1.0 - pSq) * t) / denom;

    final centerScreen = transform.viewToScreen(centerEuclidView);
    final radiusScreen = radiusEuclidView * transform.screenRadius;

    if (radiusScreen <= 0.0) return;

    final isCreationPick = obj.id == scene.creationFirstObjId;
    if (isSelected || isCreationPick) {
      final haloPaint = Paint()
        ..color = isSelected
            ? Colors.amber.withOpacity(0.35)
            : scene.settings.theme.scheme.primary.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = obj.strokeWidth + 6.0;
      canvas.drawCircle(centerScreen, radiusScreen, haloPaint);
    }

    if (obj.filled) {
      final fillPaint = Paint()
        ..color = Color(obj.color).withOpacity(0.18)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(centerScreen, radiusScreen, fillPaint);
    }

    final strokePaint = Paint()
      ..color = Color(obj.color)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? obj.strokeWidth + 1.5 : obj.strokeWidth;
    canvas.drawCircle(centerScreen, radiusScreen, strokePaint);
  }

  void _drawLine(
    Canvas canvas,
    CoordinateTransform transform,
    LineObject obj, {
    required bool isSelected,
  }) {
    if (obj.line == null) return;

    // Pick two representative points on the geodesic to transform into view coordinates:
    HyperbolicPoint p1, p2;
    if (obj.p1 != null && obj.p2 != null) {
      p1 = obj.p1!;
      p2 = obj.p2!;
    } else if (obj.line!.isDiameter) {
      p1 = const HyperbolicPoint.origin();
      p2 = obj.line!.direction.scale(0.5);
    } else {
      final line = obj.line!;
      final double d = line.euclideanCenter.magnitude;
      final double rClosest = d - line.euclideanRadius;
      p1 = line.euclideanCenter.normalized().scale(rClosest);
      p2 = HyperbolicPoint(
        line.euclideanCenter.x +
            line.euclideanRadius *
                math.cos(line.startAngle + line.sweepAngle * 0.25),
        line.euclideanCenter.y +
            line.euclideanRadius *
                math.sin(line.startAngle + line.sweepAngle * 0.25),
      );
    }

    final w1 = transform.diskToView(p1);
    final w2 = transform.diskToView(p2);

    if (w1 == w2) return;

    final viewLine = HyperbolicLine.fromPoints(w1, w2);

    final strokePaint = Paint()
      ..color = Color(obj.color)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? obj.strokeWidth + 1.5 : obj.strokeWidth;

    final isCreationPick = obj.id == scene.creationFirstObjId;
    if (isSelected || isCreationPick) {
      final haloPaint = Paint()
        ..color = isSelected
            ? Colors.amber.withOpacity(0.35)
            : scene.settings.theme.scheme.primary.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = obj.strokeWidth + 6.0;
      _renderLineGeometry(
        canvas,
        transform,
        viewLine,
        obj.lineStyle,
        w1,
        w2,
        haloPaint,
      );
    }

    _renderLineGeometry(
      canvas,
      transform,
      viewLine,
      obj.lineStyle,
      w1,
      w2,
      strokePaint,
    );
  }

  void _renderLineGeometry(
    Canvas canvas,
    CoordinateTransform transform,
    HyperbolicLine viewLine,
    LineStyle style,
    HyperbolicPoint w1,
    HyperbolicPoint w2,
    Paint paint,
  ) {
    if (viewLine.isDiameter) {
      // Euclidean straight line
      Offset startScreen, endScreen;
      if (style == LineStyle.segment) {
        startScreen = transform.viewToScreen(w1);
        endScreen = transform.viewToScreen(w2);
      } else if (style == LineStyle.ray) {
        startScreen = transform.viewToScreen(w1);
        final d1 = w2.euclideanDistance(viewLine.idealPoint1);
        final d2 = w2.euclideanDistance(viewLine.idealPoint2);
        final ideal = d1 < d2 ? viewLine.idealPoint1 : viewLine.idealPoint2;
        endScreen = transform.viewToScreen(ideal);
      } else {
        startScreen = transform.viewToScreen(viewLine.idealPoint1);
        endScreen = transform.viewToScreen(viewLine.idealPoint2);
      }
      canvas.drawLine(startScreen, endScreen, paint);
    } else {
      // Circular arc
      final centerScreen = transform.viewToScreen(viewLine.euclideanCenter);
      final radiusScreen = viewLine.euclideanRadius * transform.screenRadius;
      final rect = Rect.fromCircle(center: centerScreen, radius: radiusScreen);

      if (style == LineStyle.segment) {
        final s1 = transform.viewToScreen(w1);
        final s2 = transform.viewToScreen(w2);
        final mid = HyperbolicSegment(w1, w2).midpoint;
        final sm = transform.viewToScreen(mid);

        final (startAngle, sweepAngle) = _arcFromPoints(
          centerScreen,
          s1,
          sm,
          s2,
        );
        canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      } else if (style == LineStyle.ray) {
        final s1 = transform.viewToScreen(w1);
        final s2 = transform.viewToScreen(w2);
        final sIdeal1 = transform.viewToScreen(viewLine.idealPoint1);
        final sIdeal2 = transform.viewToScreen(viewLine.idealPoint2);

        final (start1, sweep1) = _arcFromPoints(centerScreen, s1, s2, sIdeal1);
        final (start2, sweep2) = _arcFromPoints(centerScreen, s1, s2, sIdeal2);
        final (startAngle, sweepAngle) = sweep1.abs() <= sweep2.abs()
            ? (start1, sweep1)
            : (start2, sweep2);
        canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      } else {
        // Full line across disk:
        final sIdeal1 = transform.viewToScreen(viewLine.idealPoint1);
        final sIdeal2 = transform.viewToScreen(viewLine.idealPoint2);

        // Point on geodesic closest to origin inside disk:
        final double d = viewLine.euclideanCenter.magnitude;
        final double rClosest = d - viewLine.euclideanRadius;
        final midView = viewLine.euclideanCenter.normalized().scale(rClosest);
        final sMid = transform.viewToScreen(midView);

        final (startAngle, sweepAngle) = _arcFromPoints(
          centerScreen,
          sIdeal1,
          sMid,
          sIdeal2,
        );
        canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      }
    }
  }

  (double, double) _arcFromPoints(
    Offset center,
    Offset start,
    Offset through,
    Offset end,
  ) {
    final a1 = math.atan2(start.dy - center.dy, start.dx - center.dx);
    final am = math.atan2(through.dy - center.dy, through.dx - center.dx);
    final a2 = math.atan2(end.dy - center.dy, end.dx - center.dx);

    double sweep = (a2 - a1) % (2 * math.pi);
    double midAngle = (am - a1) % (2 * math.pi);

    if (midAngle > sweep) {
      sweep -= 2 * math.pi;
    }
    return (a1, sweep);
  }

  void _drawPoint(
    Canvas canvas,
    CoordinateTransform transform,
    PointObject obj, {
    required bool isSelected,
    required bool isHovered,
  }) {
    final pos = transform.diskToScreen(obj.point);

    final isCreationPick =
        obj.id == scene.creationFirstObjId ||
        obj.id == scene.creationSecondObjId;

    if (isSelected) {
      final haloPaint = Paint()
        ..color = Colors.amber.withOpacity(0.45)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 13.0, haloPaint);
    } else if (isCreationPick) {
      final pickPaint = Paint()
        ..color = scene.settings.theme.scheme.primary.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 13.0, pickPaint);
    } else if (isHovered) {
      final hoverPaint = Paint()
        ..color = scene.settings.theme.scheme.primary.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(pos, 9.0, hoverPaint);
    }

    final fillPaint = Paint()
      ..color = Color(obj.color)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 6.0, fillPaint);

    final borderPaint = Paint()
      ..color = scene.settings.backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(pos, 6.0, borderPaint);

    if (obj.locked) {
      final lockPaint = Paint()
        ..color = Colors.red.shade700
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 2.5, lockPaint);
    }

    // Text label
    if (obj.name.isNotEmpty) {
      final textSpan = TextSpan(
        text: obj.name,
        style: TextStyle(
          color: scene.settings.theme.scheme.onSurface,
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          backgroundColor: scene.settings.backgroundColor.withOpacity(0.75),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(pos.dx + 8.0, pos.dy - 8.0));
    }
  }

  void _drawToolPreview(Canvas canvas, CoordinateTransform transform) {
    final first = scene.creationFirstPoint;
    final hover = scene.hoverPoint;
    if (first == null || hover == null) return;

    final previewPaint = Paint()
      ..color = scene.settings.theme.scheme.primary.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    if (scene.currentTool.value == HyperbolicTool.line) {
      if (first != hover) {
        final line = HyperbolicLine.fromPoints(first, hover);
        final w1 = transform.diskToView(first);
        final w2 = transform.diskToView(hover);
        final viewLine = HyperbolicLine.fromPoints(w1, w2);
        _renderLineGeometry(
          canvas,
          transform,
          viewLine,
          LineStyle.segment,
          w1,
          w2,
          previewPaint,
        );
      }
    } else if (scene.currentTool.value == HyperbolicTool.circle) {
      if (first != hover) {
        final circle = HyperbolicCircle.fromPoints(first, hover);
        final centerView = transform.diskToView(circle.hyperbolicCenter);
        final double rho = circle.hyperbolicRadius;
        final double t = tanh(rho / 2.0);
        final double pSq = centerView.magnitudeSquared;
        final double denom = 1.0 - pSq * t * t;
        if (denom.abs() > 1e-12) {
          final centerEuclidView = centerView.scale((1.0 - t * t) / denom);
          final double radiusEuclidView = ((1.0 - pSq) * t) / denom;
          final centerScreen = transform.viewToScreen(centerEuclidView);
          final radiusScreen = radiusEuclidView * transform.screenRadius;
          canvas.drawCircle(centerScreen, radiusScreen, previewPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
