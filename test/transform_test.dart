import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyperbolic/transform.dart';

void main() {
  group('HyperbolicPoint and basic complex arithmetic', () {
    test('constructors and components', () {
      const p1 = HyperbolicPoint(0.3, -0.4);
      expect(p1.x, equals(0.3));
      expect(p1.y, equals(-0.4));
      expect(p1.magnitudeSquared, closeTo(0.25, 1e-12));
      expect(p1.magnitude, closeTo(0.5, 1e-12));
      expect(p1.isInsideDisk, isTrue);

      final pPolar = HyperbolicPoint.fromPolar(0.6, math.pi / 3);
      expect(pPolar.magnitude, closeTo(0.6, 1e-12));
      expect(pPolar.arg, closeTo(math.pi / 3, 1e-12));

      const pOrigin = HyperbolicPoint.origin();
      expect(pOrigin.magnitude, equals(0.0));
      expect(pOrigin.x, equals(0.0));
      expect(pOrigin.y, equals(0.0));
    });

    test('vector and complex operations', () {
      const a = HyperbolicPoint(0.2, 0.4);
      const b = HyperbolicPoint(0.1, -0.2);

      final sum = a + b;
      expect(sum.x, closeTo(0.3, 1e-12));
      expect(sum.y, closeTo(0.2, 1e-12));

      final diff = a - b;
      expect(diff.x, closeTo(0.1, 1e-12));
      expect(diff.y, closeTo(0.6, 1e-12));

      final scaled = a.scale(2.5);
      expect(scaled.x, closeTo(0.5, 1e-12));
      expect(scaled.y, closeTo(1.0, 1e-12));

      expect(a.dot(b), closeTo(0.2 * 0.1 + 0.4 * (-0.2), 1e-12));
      expect(a.cross(b), closeTo(0.2 * (-0.2) - 0.4 * 0.1, 1e-12));

      // Complex multiplication & division: (a * b) / b == a
      final prod = a.complexMul(b);
      final div = prod.complexDiv(b);
      expect(div.x, closeTo(a.x, 1e-12));
      expect(div.y, closeTo(a.y, 1e-12));
    });

    test('circle inversion across unit circle', () {
      const p = HyperbolicPoint(0.3, 0.4); // |p| = 0.5
      final pInv = p.invertAcrossUnitCircle()!;
      expect(pInv.magnitude, closeTo(2.0, 1e-12));
      expect(p.dot(pInv), closeTo(1.0, 1e-12));
      expect(p.arg, closeTo(pInv.arg, 1e-12));

      // Inverting twice recovers original point:
      final pDoubleInv = pInv.invertAcrossUnitCircle()!;
      expect(pDoubleInv.x, closeTo(p.x, 1e-12));
      expect(pDoubleInv.y, closeTo(p.y, 1e-12));
    });
  });

  group('Hyperbolic Distance and Metric Axioms', () {
    test('positive definiteness', () {
      const p1 = HyperbolicPoint(0.1, 0.2);
      const p2 = HyperbolicPoint(0.1, 0.2);
      const p3 = HyperbolicPoint(-0.3, 0.4);

      expect(p1.hyperbolicDistance(p2), equals(0.0));
      expect(p1.pseudoDistance(p2), equals(0.0));
      expect(p1.hyperbolicDistance(p3), greaterThan(0.0));
    });

    test('symmetry', () {
      const u = HyperbolicPoint(0.25, -0.35);
      const v = HyperbolicPoint(-0.4, 0.5);

      expect(u.hyperbolicDistance(v), closeTo(v.hyperbolicDistance(u), 1e-12));
      expect(u.pseudoDistance(v), closeTo(v.pseudoDistance(u), 1e-12));
    });

    test('triangle inequality: d(u, w) <= d(u, v) + d(v, w)', () {
      const u = HyperbolicPoint(-0.5, 0.2);
      const v = HyperbolicPoint(0.1, -0.4);
      const w = HyperbolicPoint(0.6, 0.3);

      final double dUW = u.hyperbolicDistance(w);
      final double dUV = u.hyperbolicDistance(v);
      final double dVW = v.hyperbolicDistance(w);

      expect(dUW, lessThanOrEqualTo(dUV + dVW + 1e-12));
    });

    test('distance from origin matches 2 * artanh(r)', () {
      for (double r = 0.05; r < 0.95; r += 0.1) {
        final pt = HyperbolicPoint.fromPolar(r, 0.7);
        const origin = HyperbolicPoint.origin();
        final double expected = math.log((1.0 + r) / (1.0 - r));
        expect(pt.hyperbolicDistance(origin), closeTo(expected, 1e-12));
        expect(radiusToHyperbolicDistance(r), closeTo(expected, 1e-12));
        expect(hyperbolicDistanceToRadius(expected), closeTo(r, 1e-12));
      }
    });
  });

  group('Möbius Disk Automorphisms (Isometries)', () {
    test('maps translation point to origin', () {
      const a = HyperbolicPoint(0.4, -0.3);
      final m = MobiusTransform.translationOnly(a);
      final mapped = m.apply(a);
      expect(mapped.magnitude, closeTo(0.0, 1e-12));
    });

    test('is invertible: M^-1(M(z)) == z and M(M^-1(w)) == w', () {
      const a = HyperbolicPoint(-0.35, 0.45);
      final m = MobiusTransform(translation: a, rotation: 1.15);

      final testPoints = [
        const HyperbolicPoint.origin(),
        const HyperbolicPoint(0.2, 0.3),
        const HyperbolicPoint(-0.5, -0.4),
        const HyperbolicPoint(0.7, -0.1),
      ];

      for (final z in testPoints) {
        final w = m.apply(z);
        expect(w.isInsideDisk, isTrue);
        final zRecovered = m.inverse(w);
        expect(zRecovered.x, closeTo(z.x, 1e-12));
        expect(zRecovered.y, closeTo(z.y, 1e-12));
      }
    });

    test('preserves hyperbolic distance: d(M(u), M(v)) == d(u, v)', () {
      const a = HyperbolicPoint(0.3, 0.4);
      final m = MobiusTransform(translation: a, rotation: 0.85);

      const u = HyperbolicPoint(-0.2, 0.5);
      const v = HyperbolicPoint(0.4, -0.3);

      final double dOriginal = u.hyperbolicDistance(v);
      final double dTransformed = m.apply(u).hyperbolicDistance(m.apply(v));

      expect(dTransformed, closeTo(dOriginal, 1e-11));
    });

    test('composition: (M1 o M2)(z) == M1(M2(z))', () {
      const a1 = HyperbolicPoint(0.3, -0.2);
      const a2 = HyperbolicPoint(-0.1, 0.4);
      final m1 = MobiusTransform(translation: a1, rotation: 0.5);
      final m2 = MobiusTransform(translation: a2, rotation: -0.8);

      final composed = m1.compose(m2);

      const z = HyperbolicPoint(0.2, 0.3);
      final expected = m1.apply(m2.apply(z));
      final actual = composed.apply(z);

      expect(actual.x, closeTo(expected.x, 1e-11));
      expect(actual.y, closeTo(expected.y, 1e-11));
    });
  });

  group('Hyperbolic Circles', () {
    test('converts between hyperbolic and Euclidean representation', () {
      const centerH = HyperbolicPoint(0.3, 0.2);
      const double rhoH = 1.2;

      final circle = HyperbolicCircle(
        hyperbolicCenter: centerH,
        hyperbolicRadius: rhoH,
      );

      // Verify all points on circle are equidistant in hyperbolic distance
      for (double angle = 0.0; angle < 2 * math.pi; angle += 0.5) {
        final pt = circle.pointAtAngle(angle);
        expect(pt.isInsideDisk, isTrue);
        expect(centerH.hyperbolicDistance(pt), closeTo(rhoH, 1e-11));
      }

      // Verify round-trip through Euclidean constructor
      final reconstructed = HyperbolicCircle.fromEuclidean(
        circle.euclideanCenter,
        circle.euclideanRadius,
      );

      expect(reconstructed.hyperbolicCenter.x, closeTo(centerH.x, 1e-11));
      expect(reconstructed.hyperbolicCenter.y, closeTo(centerH.y, 1e-11));
      expect(reconstructed.hyperbolicRadius, closeTo(rhoH, 1e-11));
    });
  });

  group('Hyperbolic Geodesics (Lines)', () {
    test('diameter through origin when collinear', () {
      const p1 = HyperbolicPoint.origin();
      const p2 = HyperbolicPoint(0.4, 0.4);

      final line = HyperbolicLine.fromPoints(p1, p2);
      expect(line.isDiameter, isTrue);
      expect(line.containsPoint(p1), isTrue);
      expect(line.containsPoint(p2), isTrue);
      expect(line.containsPoint(const HyperbolicPoint(-0.3, -0.3)), isTrue);
      expect(line.containsPoint(const HyperbolicPoint(0.3, -0.3)), isFalse);
    });

    test('orthogonal circle when non-collinear with origin', () {
      const p1 = HyperbolicPoint(-0.4, 0.2);
      const p2 = HyperbolicPoint(0.5, -0.1);

      final line = HyperbolicLine.fromPoints(p1, p2);
      expect(line.isDiameter, isFalse);

      // Verify circle is orthogonal to unit circle: |C_L|^2 == R_L^2 + 1
      final double cMagSq = line.euclideanCenter.magnitudeSquared;
      final double rSq = line.euclideanRadius * line.euclideanRadius;
      expect(cMagSq - rSq, closeTo(1.0, 1e-10));

      // Line contains p1 and p2
      expect(line.containsPoint(p1), isTrue);
      expect(line.containsPoint(p2), isTrue);
    });

    test('line from point and angle', () {
      const p = HyperbolicPoint(0.2, 0.3);
      const double angle = math.pi / 4;

      final line = HyperbolicLine.fromPointAndAngle(p, angle);
      expect(line.containsPoint(p), isTrue);

      final tangent = line.tangentAt(p);
      final double tangentAngle = math.atan2(tangent.y, tangent.x);
      // Tangent angle is either angle or angle + pi
      final double diff = (tangentAngle - angle).abs() % math.pi;
      expect(diff, closeTo(0.0, 1e-10));
    });

    test('orthogonal projection of point onto geodesic', () {
      const p1 = HyperbolicPoint(-0.4, 0.2);
      const p2 = HyperbolicPoint(0.5, -0.1);
      final line = HyperbolicLine.fromPoints(p1, p2);

      const p = HyperbolicPoint(0.1, 0.6);
      final foot = line.projectPoint(p);

      // Foot is on the line
      expect(line.containsPoint(foot), isTrue);

      // Perpendicular geodesic through p and foot is orthogonal to line
      final linePF = HyperbolicLine.fromPoints(p, foot);
      final tangentL = line.tangentAt(foot);
      final tangentPF = linePF.tangentAt(foot);
      // Tangents are orthogonal: dot product is 0
      expect(tangentL.dot(tangentPF).abs(), closeTo(0.0, 1e-10));

      // The perpendicular line constructed at foot passes through p
      final perpLine = line.perpendicularAt(foot);
      expect(perpLine.containsPoint(p), isTrue);

      // Distance from p to foot is strictly smaller than distance to nearby points on line
      final dFoot = p.hyperbolicDistance(foot);
      final pNeighbor = foot + line.tangentAt(foot).scale(0.01);
      expect(dFoot, lessThan(p.hyperbolicDistance(pNeighbor)));
    });

    test('hyperbolic segment midpoint and fraction', () {
      const a = HyperbolicPoint(-0.3, 0.4);
      const b = HyperbolicPoint(0.5, -0.2);
      final segment = HyperbolicSegment(a, b);

      final mid = segment.midpoint;
      expect(segment.containsPoint(mid), isTrue);

      final double dTotal = segment.length;
      final double d1 = a.hyperbolicDistance(mid);
      final double d2 = mid.hyperbolicDistance(b);

      expect(d1, closeTo(dTotal / 2.0, 1e-11));
      expect(d2, closeTo(dTotal / 2.0, 1e-11));
    });
  });

  group('Intersections in Poincaré Disk', () {
    test('two diameters intersect at origin', () {
      final d1 = HyperbolicLine.fromPointAndAngle(
        const HyperbolicPoint.origin(),
        0.0,
      );
      final d2 = HyperbolicLine.fromPointAndAngle(
        const HyperbolicPoint.origin(),
        math.pi / 2,
      );

      final pts = intersectLineLine(d1, d2);
      expect(pts.length, equals(1));
      expect(pts.first.magnitude, closeTo(0.0, 1e-11));
    });

    test(
      'two intersecting orthogonal circles have exactly 1 intersection inside disk',
      () {
        const p1 = HyperbolicPoint(-0.3, 0.2);
        const p2 = HyperbolicPoint(0.4, -0.3);
        final l1 = HyperbolicLine.fromPoints(p1, p2);

        const q1 = HyperbolicPoint(-0.2, -0.4);
        const q2 = HyperbolicPoint(0.3, 0.5);
        final l2 = HyperbolicLine.fromPoints(q1, q2);

        final pts = intersectLineLine(l1, l2);
        expect(pts.length, equals(1));
        final intersection = pts.first;

        expect(intersection.isInsideDisk, isTrue);
        expect(l1.containsPoint(intersection), isTrue);
        expect(l2.containsPoint(intersection), isTrue);
      },
    );

    test('ultraparallel lines do not intersect', () {
      // Two geodesics that do not meet inside disk
      const p1 = HyperbolicPoint(-0.6, 0.6);
      const p2 = HyperbolicPoint(-0.6, -0.6);
      final l1 = HyperbolicLine.fromPoints(p1, p2);

      const q1 = HyperbolicPoint(0.6, 0.6);
      const q2 = HyperbolicPoint(0.6, -0.6);
      final l2 = HyperbolicLine.fromPoints(q1, q2);

      final pts = intersectLineLine(l1, l2);
      expect(pts.isEmpty, isTrue);
    });

    test('line and circle intersections', () {
      final circle = HyperbolicCircle(
        hyperbolicCenter: const HyperbolicPoint(0.1, 0.1),
        hyperbolicRadius: 1.0,
      );
      final line = HyperbolicLine.fromPoints(
        const HyperbolicPoint(-0.5, 0.1),
        const HyperbolicPoint(0.5, 0.1),
      );

      final pts = intersectLineCircle(line, circle);
      expect(pts.length, equals(2));
      for (final pt in pts) {
        expect(pt.isInsideDisk, isTrue);
        expect(line.containsPoint(pt), isTrue);
        expect(circle.contains(pt), isTrue);
      }
    });

    test('circle and circle intersections', () {
      final c1 = HyperbolicCircle(
        hyperbolicCenter: const HyperbolicPoint(-0.15, 0.0),
        hyperbolicRadius: 0.8,
      );
      final c2 = HyperbolicCircle(
        hyperbolicCenter: const HyperbolicPoint(0.15, 0.0),
        hyperbolicRadius: 0.8,
      );

      final pts = intersectCircleCircle(c1, c2);
      expect(pts.length, equals(2));
      for (final pt in pts) {
        expect(pt.isInsideDisk, isTrue);
        expect(c1.contains(pt), isTrue);
        expect(c2.contains(pt), isTrue);
      }
    });
  });

  group('Hyperbolic Angles and Triangle Area (Gauss-Bonnet)', () {
    test('hyperbolic angle at origin equals Euclidean angle', () {
      const origin = HyperbolicPoint.origin();
      const a = HyperbolicPoint(0.5, 0.0);
      final b = HyperbolicPoint(0.0, 0.5);

      final double angle = angleBetween(a, origin, b);
      expect(angle, closeTo(math.pi / 2, 1e-11));
    });

    test('hyperbolic triangle angle sum is strictly less than pi', () {
      const a = HyperbolicPoint(-0.4, -0.3);
      const b = HyperbolicPoint(0.5, -0.2);
      const c = HyperbolicPoint(0.1, 0.6);

      final double angleA = angleBetween(b, a, c);
      final double angleB = angleBetween(a, b, c);
      final double angleC = angleBetween(a, c, b);
      final double sum = angleA + angleB + angleC;

      expect(sum, lessThan(math.pi));
      final double area = hyperbolicTriangleArea(a, b, c);
      expect(area, closeTo(math.pi - sum, 1e-11));
      expect(area, greaterThan(0.0));
    });
  });

  group('CoordinateTransform Viewport Navigation', () {
    test('conversions round-trip accurately', () {
      final transform = CoordinateTransform(
        size: const Size(1000.0, 800.0),
        pan: const Offset(50.0, -30.0),
        zoom: 1.5,
      );

      final testPoints = [
        const HyperbolicPoint.origin(),
        const HyperbolicPoint(0.25, -0.4),
        const HyperbolicPoint(-0.6, 0.3),
      ];

      for (final p in testPoints) {
        final screen = transform.diskToScreen(p);
        final pRecovered = transform.screenToDisk(screen);
        expect(pRecovered.x, closeTo(p.x, 1e-11));
        expect(pRecovered.y, closeTo(p.y, 1e-11));
      }
    });

    test('translateDiskCenter shifts point to screen center', () {
      final transform = CoordinateTransform(size: const Size(800.0, 600.0));

      const target = HyperbolicPoint(0.35, -0.25);
      transform.translateDiskCenter(target);

      final screenPos = transform.diskToScreen(target);
      expect(screenPos.dx, closeTo(transform.screenCenter.dx, 1e-11));
      expect(screenPos.dy, closeTo(transform.screenCenter.dy, 1e-11));
    });
  });
}
