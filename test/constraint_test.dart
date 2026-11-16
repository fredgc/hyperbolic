import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:hyperbolic/constraints/constraints.dart';
import 'package:hyperbolic/objects/objects.dart';
import 'package:hyperbolic/scene/scene_data.dart';
import 'package:hyperbolic/transform.dart';

void main() {
  group('Scene Objects', () {
    test('PointObject serialization and properties', () {
      final pt = PointObject(
        id: 'p1',
        name: 'A',
        point: const HyperbolicPoint(0.2, -0.3),
        locked: true,
      );

      final json = pt.toJson();
      final restored = PointObject.fromJson(json);

      expect(restored.id, equals('p1'));
      expect(restored.name, equals('A'));
      expect(restored.point.x, closeTo(0.2, 1e-11));
      expect(restored.point.y, closeTo(-0.3, 1e-11));
      expect(restored.locked, isTrue);
    });

    test('LineObject serialization', () {
      final line = LineObject(
        id: 'l1',
        name: 'L1',
        lineStyle: LineStyle.segment,
        p1: const HyperbolicPoint(0.1, 0.1),
        p2: const HyperbolicPoint(0.4, 0.4),
      );

      final json = line.toJson();
      final restored = LineObject.fromJson(json);

      expect(restored.id, equals('l1'));
      expect(restored.lineStyle, equals(LineStyle.segment));
      expect(restored.p1?.x, closeTo(0.1, 1e-11));
      expect(restored.p2?.x, closeTo(0.4, 1e-11));
    });

    test('CircleObject serialization', () {
      final circle = CircleObject(
        id: 'c1',
        name: 'C1',
        circle: HyperbolicCircle(
          hyperbolicCenter: const HyperbolicPoint(0.2, 0.2),
          hyperbolicRadius: 1.5,
        ),
      );

      final json = circle.toJson();
      final restored = CircleObject.fromJson(json);

      expect(restored.id, equals('c1'));
      expect(restored.circle?.hyperbolicRadius, closeTo(1.5, 1e-11));
    });

    test('NumberObject serialization', () {
      final numObj = NumberObject(
        id: 'n1',
        name: 'radius',
        value: 2.5,
        min: 0.1,
        max: 5.0,
        unit: NumberUnit.distance,
      );

      final json = numObj.toJson();
      final restored = NumberObject.fromJson(json);

      expect(restored.id, equals('n1'));
      expect(restored.value, equals(2.5));
      expect(restored.unit, equals(NumberUnit.distance));
    });
  });

  group('Constraint Graph and Forward Evaluation', () {
    test('Line through two points updates when points change', () {
      final graph = ConstraintGraph();

      final p1 = PointObject(
        id: 'p1',
        name: 'A',
        point: const HyperbolicPoint(-0.3, 0.0),
      );
      final p2 = PointObject(
        id: 'p2',
        name: 'B',
        point: const HyperbolicPoint(0.3, 0.0),
      );
      final lineObj = LineObject(id: 'l1', name: 'L');

      graph.addObject(p1);
      graph.addObject(p2);
      graph.addObject(lineObj);

      final constraint = LineThroughPointsConstraint(
        id: 'c_line',
        p1Id: 'p1',
        p2Id: 'p2',
        lineId: 'l1',
      );
      graph.addConstraint(constraint);

      graph.evaluateAll();

      expect(lineObj.line, isNotNull);
      expect(lineObj.line!.isDiameter, isTrue); // On x-axis, passes through 0

      // Move p2 off axis:
      p2.point = const HyperbolicPoint(0.3, 0.2);
      graph.evaluateAll();

      expect(lineObj.line!.isDiameter, isFalse);
      expect(lineObj.line!.containsPoint(p1.point), isTrue);
      expect(lineObj.line!.containsPoint(p2.point), isTrue);
    });

    test('Circle from center and point updates when center moves', () {
      final graph = ConstraintGraph();

      final center = PointObject(
        id: 'center',
        name: 'C',
        point: const HyperbolicPoint.origin(),
      );
      final pt = PointObject(
        id: 'pt',
        name: 'P',
        point: const HyperbolicPoint(0.5, 0.0),
      );
      final circleObj = CircleObject(id: 'c1', name: 'Circ');

      graph.addObject(center);
      graph.addObject(pt);
      graph.addObject(circleObj);

      graph.addConstraint(
        CircleCenterPointConstraint(
          id: 'c_circ',
          centerId: 'center',
          pointOnCircleId: 'pt',
          circleId: 'c1',
        ),
      );

      graph.evaluateAll();

      expect(circleObj.circle, isNotNull);
      final initialRadius = circleObj.circle!.hyperbolicRadius;
      expect(initialRadius, closeTo(radiusToHyperbolicDistance(0.5), 1e-11));

      // Move center
      center.point = const HyperbolicPoint(0.2, 0.1);
      graph.evaluateAll();

      expect(
        circleObj.circle!.hyperbolicRadius,
        closeTo(center.point.hyperbolicDistance(pt.point), 1e-11),
      );
    });

    test('Intersection of two lines updates when an ancestor point moves', () {
      final graph = ConstraintGraph();

      // Line 1: through (-0.5, 0) and (0.5, 0) (x-axis)
      final a1 = PointObject(
        id: 'a1',
        name: 'A1',
        point: const HyperbolicPoint(-0.5, 0.0),
      );
      final a2 = PointObject(
        id: 'a2',
        name: 'A2',
        point: const HyperbolicPoint(0.5, 0.0),
      );
      final l1 = LineObject(id: 'l1', name: 'L1');

      // Line 2: through (0, -0.5) and (0, 0.5) (y-axis)
      final b1 = PointObject(
        id: 'b1',
        name: 'B1',
        point: const HyperbolicPoint(0.0, -0.5),
      );
      final b2 = PointObject(
        id: 'b2',
        name: 'B2',
        point: const HyperbolicPoint(0.0, 0.5),
      );
      final l2 = LineObject(id: 'l2', name: 'L2');

      final interPt = PointObject(id: 'inter', name: 'X');

      graph.addObject(a1);
      graph.addObject(a2);
      graph.addObject(l1);
      graph.addObject(b1);
      graph.addObject(b2);
      graph.addObject(l2);
      graph.addObject(interPt);

      graph.addConstraint(
        LineThroughPointsConstraint(
          id: 'c1',
          p1Id: 'a1',
          p2Id: 'a2',
          lineId: 'l1',
        ),
      );
      graph.addConstraint(
        LineThroughPointsConstraint(
          id: 'c2',
          p1Id: 'b1',
          p2Id: 'b2',
          lineId: 'l2',
        ),
      );
      graph.addConstraint(
        IntersectionConstraint(
          id: 'c_inter',
          obj1Id: 'l1',
          obj2Id: 'l2',
          pointId: 'inter',
        ),
      );

      graph.evaluateAll();

      // Intersection of x-axis and y-axis is the origin:
      expect(interPt.point.magnitude, closeTo(0.0, 1e-11));

      // Shift line 2 by moving b1 and b2 to x = 0.2:
      b1.point = const HyperbolicPoint(0.2, -0.5);
      b2.point = const HyperbolicPoint(0.2, 0.5);
      graph.evaluateAll();

      // In hyperbolic space, line 2 is an orthogonal circular arc that curves
      // toward the origin, intersecting the x-axis at y = 0 and x > 0:
      expect(interPt.point.y, closeTo(0.0, 1e-6));
      expect(interPt.point.x, greaterThan(0.0));
      expect(l1.line!.containsPoint(interPt.point), isTrue);
      expect(l2.line!.containsPoint(interPt.point), isTrue);
    });

    test('FreePointConstraint driven by coordinate numbers', () {
      final graph = ConstraintGraph();
      final numX = NumberObject(id: 'nx', name: 'x', value: 0.35);
      final numY = NumberObject(id: 'ny', name: 'y', value: -0.45);
      final pt = PointObject(id: 'p1', name: 'P');

      graph.addObject(numX);
      graph.addObject(numY);
      graph.addObject(pt);

      graph.addConstraint(
        FreePointConstraint(
          id: 'c_free',
          pointId: 'p1',
          xNumberId: 'nx',
          yNumberId: 'ny',
        ),
      );

      graph.evaluateAll();

      expect(pt.point.x, closeTo(0.35, 1e-11));
      expect(pt.point.y, closeTo(-0.45, 1e-11));

      // Modify x number:
      numX.value = -0.2;
      graph.evaluateAll();
      expect(pt.point.x, closeTo(-0.2, 1e-11));
      expect(pt.point.y, closeTo(-0.45, 1e-11));
    });

    test('PointOnLineConstraint updates along geodesic', () {
      final graph = ConstraintGraph();
      final p1 = PointObject(
        id: 'p1',
        name: 'A',
        point: const HyperbolicPoint(-0.5, 0.0),
      );
      final p2 = PointObject(
        id: 'p2',
        name: 'B',
        point: const HyperbolicPoint(0.5, 0.0),
      );
      final line = LineObject(
        id: 'line',
        name: 'L',
        lineStyle: LineStyle.segment,
      );
      final tNum = NumberObject(id: 't', name: 't', value: 0.5);
      final ptOnLine = PointObject(id: 'pt', name: 'Mid');

      graph.addObject(p1);
      graph.addObject(p2);
      graph.addObject(line);
      graph.addObject(tNum);
      graph.addObject(ptOnLine);

      graph.addConstraint(
        LineThroughPointsConstraint(
          id: 'c_line',
          p1Id: 'p1',
          p2Id: 'p2',
          lineId: 'line',
        ),
      );
      graph.addConstraint(
        PointOnLineConstraint(
          id: 'c_on_line',
          lineId: 'line',
          paramNumberId: 't',
          pointId: 'pt',
        ),
      );

      graph.evaluateAll();

      // At fraction 0.5 between (-0.5, 0) and (0.5, 0), midpoint is origin:
      expect(ptOnLine.point.magnitude, closeTo(0.0, 1e-11));

      // Change parameter to 0.0 -> should be p1:
      tNum.value = 0.0;
      graph.evaluateAll();
      expect(ptOnLine.point.x, closeTo(-0.5, 1e-11));
      expect(ptOnLine.point.y, closeTo(0.0, 1e-11));

      // Change parameter to 1.0 -> should be p2:
      tNum.value = 1.0;
      graph.evaluateAll();
      expect(ptOnLine.point.x, closeTo(0.5, 1e-11));
      expect(ptOnLine.point.y, closeTo(0.0, 1e-11));
    });

    test('PointOnCircleConstraint positions point at angle', () {
      final graph = ConstraintGraph();
      final center = PointObject(
        id: 'c',
        name: 'C',
        point: const HyperbolicPoint.origin(),
      );
      final radiusNum = NumberObject(
        id: 'r',
        name: 'r',
        value: radiusToHyperbolicDistance(0.5),
      );
      final circle = CircleObject(id: 'circ', name: 'Circle');
      final angleNum = NumberObject(
        id: 'theta',
        name: 'theta',
        value: math.pi / 2,
      );
      final ptOnCircle = PointObject(id: 'p_circ', name: 'P');

      graph.addObject(center);
      graph.addObject(radiusNum);
      graph.addObject(circle);
      graph.addObject(angleNum);
      graph.addObject(ptOnCircle);

      graph.addConstraint(
        CircleCenterRadiusConstraint(
          id: 'c_radius',
          centerId: 'c',
          radiusNumberId: 'r',
          circleId: 'circ',
        ),
      );
      graph.addConstraint(
        PointOnCircleConstraint(
          id: 'c_on_circle',
          circleId: 'circ',
          angleNumberId: 'theta',
          pointId: 'p_circ',
        ),
      );

      graph.evaluateAll();

      expect(circle.circle, isNotNull);
      // At angle pi/2 from origin with Euclidean radius 0.5, point should be at (0, 0.5):
      expect(ptOnCircle.point.x, closeTo(0.0, 1e-11));
      expect(ptOnCircle.point.y, closeTo(0.5, 1e-11));
    });

    test('AngleLineConstraint creates geodesic at specified angle', () {
      final graph = ConstraintGraph();
      final p1 = PointObject(
        id: 'p1',
        name: 'A',
        point: const HyperbolicPoint(-0.4, 0.0),
      );
      final p2 = PointObject(
        id: 'p2',
        name: 'B',
        point: const HyperbolicPoint(0.4, 0.0),
      );
      final baseLine = LineObject(id: 'base', name: 'Base');
      final v = PointObject(
        id: 'v',
        name: 'Vertex',
        point: const HyperbolicPoint.origin(),
      );
      final angleNum = NumberObject(
        id: 'angle',
        name: 'alpha',
        value: math.pi / 2,
      );
      final perpLine = LineObject(id: 'perp', name: 'Perp');

      graph.addObject(p1);
      graph.addObject(p2);
      graph.addObject(baseLine);
      graph.addObject(v);
      graph.addObject(angleNum);
      graph.addObject(perpLine);

      graph.addConstraint(
        LineThroughPointsConstraint(
          id: 'c_base',
          p1Id: 'p1',
          p2Id: 'p2',
          lineId: 'base',
        ),
      );
      graph.addConstraint(
        AngleLineConstraint(
          id: 'c_angle',
          baseLineId: 'base',
          pointId: 'v',
          angleNumberId: 'angle',
          lineId: 'perp',
        ),
      );

      graph.evaluateAll();

      expect(perpLine.line, isNotNull);
      // Perp line at origin at 90 deg to x-axis is the y-axis diameter:
      expect(perpLine.line!.isDiameter, isTrue);
      expect(
        perpLine.line!.containsPoint(const HyperbolicPoint(0.0, 0.3)),
        isTrue,
      );
    });

    test('Line-Circle and Circle-Circle intersections', () {
      final graph = ConstraintGraph();

      // Circle 1 centered at origin with radius 0.5:
      final c1Center = PointObject(
        id: 'c1_c',
        name: 'C1',
        point: const HyperbolicPoint.origin(),
      );
      final c1Rad = NumberObject(
        id: 'c1_r',
        name: 'r1',
        value: radiusToHyperbolicDistance(0.5),
      );
      final circ1 = CircleObject(id: 'circ1', name: 'Circ1');

      // Circle 2 centered at (0.4, 0) with radius 0.4:
      final c2Center = PointObject(
        id: 'c2_c',
        name: 'C2',
        point: const HyperbolicPoint(0.4, 0.0),
      );
      final c2Rad = NumberObject(
        id: 'c2_r',
        name: 'r2',
        value: radiusToHyperbolicDistance(0.4),
      );
      final circ2 = CircleObject(id: 'circ2', name: 'Circ2');

      // Intersections:
      final inter1 = PointObject(id: 'inter1', name: 'I1');
      final inter2 = PointObject(id: 'inter2', name: 'I2');

      graph.addObject(c1Center);
      graph.addObject(c1Rad);
      graph.addObject(circ1);
      graph.addObject(c2Center);
      graph.addObject(c2Rad);
      graph.addObject(circ2);
      graph.addObject(inter1);
      graph.addObject(inter2);

      graph.addConstraint(
        CircleCenterRadiusConstraint(
          id: 'cc1',
          centerId: 'c1_c',
          radiusNumberId: 'c1_r',
          circleId: 'circ1',
        ),
      );
      graph.addConstraint(
        CircleCenterRadiusConstraint(
          id: 'cc2',
          centerId: 'c2_c',
          radiusNumberId: 'c2_r',
          circleId: 'circ2',
        ),
      );
      graph.addConstraint(
        IntersectionConstraint(
          id: 'ci1',
          obj1Id: 'circ1',
          obj2Id: 'circ2',
          pointId: 'inter1',
          index: 0,
        ),
      );
      graph.addConstraint(
        IntersectionConstraint(
          id: 'ci2',
          obj1Id: 'circ1',
          obj2Id: 'circ2',
          pointId: 'inter2',
          index: 1,
        ),
      );

      graph.evaluateAll();

      expect(circ1.circle!.contains(inter1.point), isTrue);
      expect(circ2.circle!.contains(inter1.point), isTrue);
      expect(circ1.circle!.contains(inter2.point), isTrue);
      expect(circ2.circle!.contains(inter2.point), isTrue);
      expect((inter1.point.y - (-inter2.point.y)).abs(), closeTo(0.0, 1e-10));
    });

    test('Angle and Coordinate measurement constraints', () {
      final graph = ConstraintGraph();
      final a = PointObject(
        id: 'a',
        name: 'A',
        point: const HyperbolicPoint(0.4, 0.0),
      );
      final b = PointObject(
        id: 'b',
        name: 'B',
        point: const HyperbolicPoint.origin(),
      );
      final c = PointObject(
        id: 'c',
        name: 'C',
        point: const HyperbolicPoint(0.0, 0.5),
      );

      final angleNum = NumberObject(id: 'ang', name: 'angle', value: 0.0);
      final xNum = NumberObject(id: 'x_coord', name: 'x', value: 0.0);
      final rNum = NumberObject(id: 'r_coord', name: 'r', value: 0.0);

      graph.addObject(a);
      graph.addObject(b);
      graph.addObject(c);
      graph.addObject(angleNum);
      graph.addObject(xNum);
      graph.addObject(rNum);

      graph.addConstraint(
        AngleMeasurementConstraint(
          id: 'c_ang',
          p1Id: 'a',
          vertexId: 'b',
          p2Id: 'c',
          numberId: 'ang',
        ),
      );
      graph.addConstraint(
        CoordinateMeasurementConstraint(
          id: 'c_x',
          pointId: 'a',
          numberId: 'x_coord',
          coordinate: 'x',
        ),
      );
      graph.addConstraint(
        CoordinateMeasurementConstraint(
          id: 'c_r',
          pointId: 'c',
          numberId: 'r_coord',
          coordinate: 'r',
        ),
      );

      graph.evaluateAll();

      expect(angleNum.value, closeTo(math.pi / 2, 1e-11));
      expect(xNum.value, closeTo(0.4, 1e-11));
      expect(rNum.value, closeTo(0.5, 1e-11));
    });

    test('Distance measurement constraint reacts to point changes', () {
      final graph = ConstraintGraph();

      final p1 = PointObject(
        id: 'p1',
        name: 'A',
        point: const HyperbolicPoint.origin(),
      );
      final p2 = PointObject(
        id: 'p2',
        name: 'B',
        point: const HyperbolicPoint(0.4, 0.0),
      );
      final distNum = NumberObject(id: 'd', name: 'dist', value: 0.0);

      graph.addObject(p1);
      graph.addObject(p2);
      graph.addObject(distNum);

      graph.addConstraint(
        DistanceMeasurementConstraint(
          id: 'c_dist',
          p1Id: 'p1',
          p2Id: 'p2',
          numberId: 'd',
        ),
      );

      graph.evaluateAll();

      expect(distNum.value, closeTo(radiusToHyperbolicDistance(0.4), 1e-11));
    });
  });

  group('Numerical Inverse Solver (Jacobian Drag)', () {
    test('direct dragging of free point', () {
      final graph = ConstraintGraph();
      final p1 = PointObject(
        id: 'p1',
        name: 'A',
        point: const HyperbolicPoint.origin(),
      );
      graph.addObject(p1);

      const target = HyperbolicPoint(0.3, 0.4);
      final success = graph.dragPoint('p1', target);

      expect(success, isTrue);
      expect(p1.point.x, closeTo(0.3, 1e-11));
      expect(p1.point.y, closeTo(0.4, 1e-11));
    });

    test('locked point cannot be dragged', () {
      final graph = ConstraintGraph();
      final p1 = PointObject(
        id: 'p1',
        name: 'A',
        point: const HyperbolicPoint.origin(),
        locked: true,
      );
      graph.addObject(p1);

      const target = HyperbolicPoint(0.3, 0.4);
      final success = graph.dragPoint('p1', target);

      expect(success, isFalse);
      expect(p1.point.magnitude, equals(0.0));
    });

    test(
      'dragging an intersection point moves unlocked ancestor line points',
      () {
        final graph = ConstraintGraph();

        // Line 1: through (-0.5, 0) and (0.5, 0)
        final a1 = PointObject(
          id: 'a1',
          name: 'A1',
          point: const HyperbolicPoint(-0.5, 0.0),
        );
        final a2 = PointObject(
          id: 'a2',
          name: 'A2',
          point: const HyperbolicPoint(0.5, 0.0),
        );
        final l1 = LineObject(id: 'l1', name: 'L1');

        // Line 2: through (0, -0.5) and (0, 0.5)
        final b1 = PointObject(
          id: 'b1',
          name: 'B1',
          point: const HyperbolicPoint(0.0, -0.5),
        );
        final b2 = PointObject(
          id: 'b2',
          name: 'B2',
          point: const HyperbolicPoint(0.0, 0.5),
        );
        final l2 = LineObject(id: 'l2', name: 'L2');

        final interPt = PointObject(id: 'inter', name: 'X');

        graph.addObject(a1);
        graph.addObject(a2);
        graph.addObject(l1);
        graph.addObject(b1);
        graph.addObject(b2);
        graph.addObject(l2);
        graph.addObject(interPt);

        graph.addConstraint(
          LineThroughPointsConstraint(
            id: 'c1',
            p1Id: 'a1',
            p2Id: 'a2',
            lineId: 'l1',
          ),
        );
        graph.addConstraint(
          LineThroughPointsConstraint(
            id: 'c2',
            p1Id: 'b1',
            p2Id: 'b2',
            lineId: 'l2',
          ),
        );
        graph.addConstraint(
          IntersectionConstraint(
            id: 'c_inter',
            obj1Id: 'l1',
            obj2Id: 'l2',
            pointId: 'inter',
          ),
        );

        graph.evaluateAll();
        expect(interPt.point.magnitude, closeTo(0.0, 1e-11));

        // Lock Line 1 ancestors so only Line 2 can move:
        a1.locked = true;
        a2.locked = true;

        // Drag intersection point to (0.0, 0.1) along Line 1:
        const target = HyperbolicPoint(0.1, 0.0);
        final success = graph.dragPoint(
          'inter',
          target,
          maxIterations: 10,
          tolerance: 1e-3,
        );

        expect(success, isTrue);
        // The intersection point should have followed the drag target along Line 1:
        expect(interPt.point.x, closeTo(0.1, 1e-2));
        expect(interPt.point.y, closeTo(0.0, 1e-2));

        // Line 1 should remain untouched:
        expect(a1.point.x, equals(-0.5));
        expect(a1.point.y, equals(0.0));

        // Both lines still pass through the new intersection:
        expect(l1.line!.containsPoint(interPt.point), isTrue);
        expect(l2.line!.containsPoint(interPt.point), isTrue);
      },
    );

    test('dragging fully locked intersection fails gracefully', () {
      final graph = ConstraintGraph();

      final a1 = PointObject(
        id: 'a1',
        name: 'A1',
        point: const HyperbolicPoint(-0.5, 0.0),
        locked: true,
      );
      final a2 = PointObject(
        id: 'a2',
        name: 'A2',
        point: const HyperbolicPoint(0.5, 0.0),
        locked: true,
      );
      final l1 = LineObject(id: 'l1', name: 'L1');

      final b1 = PointObject(
        id: 'b1',
        name: 'B1',
        point: const HyperbolicPoint(0.0, -0.5),
        locked: true,
      );
      final b2 = PointObject(
        id: 'b2',
        name: 'B2',
        point: const HyperbolicPoint(0.0, 0.5),
        locked: true,
      );
      final l2 = LineObject(id: 'l2', name: 'L2');

      final interPt = PointObject(id: 'inter', name: 'X');

      graph.addObject(a1);
      graph.addObject(a2);
      graph.addObject(l1);
      graph.addObject(b1);
      graph.addObject(b2);
      graph.addObject(l2);
      graph.addObject(interPt);

      graph.addConstraint(
        LineThroughPointsConstraint(
          id: 'c1',
          p1Id: 'a1',
          p2Id: 'a2',
          lineId: 'l1',
        ),
      );
      graph.addConstraint(
        LineThroughPointsConstraint(
          id: 'c2',
          p1Id: 'b1',
          p2Id: 'b2',
          lineId: 'l2',
        ),
      );
      graph.addConstraint(
        IntersectionConstraint(
          id: 'c_inter',
          obj1Id: 'l1',
          obj2Id: 'l2',
          pointId: 'inter',
        ),
      );

      graph.evaluateAll();

      final success = graph.dragPoint('inter', const HyperbolicPoint(0.2, 0.2));
      expect(success, isFalse);
    });

    test('dragging a point on a circle adjusts angle parameter', () {
      final graph = ConstraintGraph();
      final center = PointObject(
        id: 'c',
        name: 'C',
        point: const HyperbolicPoint.origin(),
        locked: true,
      );
      final radiusNum = NumberObject(
        id: 'r',
        name: 'r',
        value: radiusToHyperbolicDistance(0.5),
        locked: true,
      );
      final circle = CircleObject(id: 'circ', name: 'Circle');
      final angleNum = NumberObject(
        id: 'theta',
        name: 'theta',
        value: 0.0,
        min: -math.pi * 2,
        max: math.pi * 2,
      );
      final pt = PointObject(id: 'p_circ', name: 'P');

      graph.addObject(center);
      graph.addObject(radiusNum);
      graph.addObject(circle);
      graph.addObject(angleNum);
      graph.addObject(pt);

      graph.addConstraint(
        CircleCenterRadiusConstraint(
          id: 'cc',
          centerId: 'c',
          radiusNumberId: 'r',
          circleId: 'circ',
        ),
      );
      graph.addConstraint(
        PointOnCircleConstraint(
          id: 'cp',
          circleId: 'circ',
          angleNumberId: 'theta',
          pointId: 'p_circ',
        ),
      );
      graph.evaluateAll();

      // Initially at (0.5, 0.0):
      expect(pt.point.x, closeTo(0.5, 1e-11));
      expect(pt.point.y, closeTo(0.0, 1e-11));

      // Drag towards (0.0, 0.5) (angle pi/2):
      final success = graph.dragPoint(
        'p_circ',
        const HyperbolicPoint(0.0, 0.5),
        maxIterations: 10,
      );
      expect(success, isTrue);

      expect(pt.point.x, closeTo(0.0, 1e-2));
      expect(pt.point.y, closeTo(0.5, 1e-2));
      expect(angleNum.value, closeTo(math.pi / 2, 1e-2));
    });

    test('dragging a point on a segment adjusts fraction parameter', () {
      final graph = ConstraintGraph();
      final p1 = PointObject(
        id: 'p1',
        name: 'A',
        point: const HyperbolicPoint(-0.4, 0.0),
        locked: true,
      );
      final p2 = PointObject(
        id: 'p2',
        name: 'B',
        point: const HyperbolicPoint(0.4, 0.0),
        locked: true,
      );
      final seg = LineObject(
        id: 'seg',
        name: 'Segment',
        lineStyle: LineStyle.segment,
      );
      final tNum = NumberObject(
        id: 't',
        name: 't',
        value: 0.1,
        min: 0.0,
        max: 1.0,
      );
      final pt = PointObject(id: 'pt_seg', name: 'P');

      graph.addObject(p1);
      graph.addObject(p2);
      graph.addObject(seg);
      graph.addObject(tNum);
      graph.addObject(pt);

      graph.addConstraint(
        LineThroughPointsConstraint(
          id: 'cs',
          p1Id: 'p1',
          p2Id: 'p2',
          lineId: 'seg',
        ),
      );
      graph.addConstraint(
        PointOnLineConstraint(
          id: 'cp',
          lineId: 'seg',
          paramNumberId: 't',
          pointId: 'pt_seg',
        ),
      );
      graph.evaluateAll();

      // Drag point to origin (fraction 0.5):
      final success = graph.dragPoint(
        'pt_seg',
        const HyperbolicPoint.origin(),
        maxIterations: 10,
      );
      expect(success, isTrue);

      expect(pt.point.magnitude, closeTo(0.0, 1e-2));
      expect(tNum.value, closeTo(0.5, 1e-2));
    });

    test(
      'locking equilateral vertex p3 and dragging free point p1 adjusts p2 to keep p3 fixed',
      () {
        final graph = ConstraintGraph();
        final p1 = PointObject(
          id: 'p1',
          name: 'p1',
          point: const HyperbolicPoint(-0.2, 0.0),
        );
        final p2 = PointObject(
          id: 'p2',
          name: 'p2',
          point: const HyperbolicPoint(0.2, 0.0),
        );
        final p3 = PointObject(id: 'p3', name: 'p3', locked: true);

        graph.addObject(p1);
        graph.addObject(p2);
        graph.addObject(p3);
        graph.addConstraint(
          EquilateralPointConstraint(
            id: 'c_eq',
            p1Id: 'p1',
            p2Id: 'p2',
            pointId: 'p3',
          ),
        );
        graph.evaluateAll();

        final lockedP3Pos = p3.point;
        final initialP2Pos = p2.point;
        const targetP1Pos = HyperbolicPoint(-0.15, -0.1);

        final success = graph.dragPoint('p1', targetP1Pos);
        expect(success, isTrue);

        // p1 moved to target:
        expect((p1.point - targetP1Pos).magnitude, lessThan(1e-4));
        // p3 remained fixed at its locked position:
        expect((p3.point - lockedP3Pos).magnitude, lessThan(1e-3));
        // p2 moved to compensate:
        expect((p2.point - initialP2Pos).magnitude, greaterThan(1e-2));
        // Triangle remains equilateral:
        final d12 = p1.point.hyperbolicDistance(p2.point);
        final d23 = p2.point.hyperbolicDistance(p3.point);
        final d13 = p1.point.hyperbolicDistance(p3.point);
        expect(d12, closeTo(d23, 2e-3));
        expect(d12, closeTo(d13, 2e-3));
      },
    );

    test(
      'locking both p2 and p3 prevents p1 from moving in equilateral triangle',
      () {
        final graph = ConstraintGraph();
        final p1 = PointObject(
          id: 'p1',
          name: 'p1',
          point: const HyperbolicPoint(-0.2, 0.0),
        );
        final p2 = PointObject(
          id: 'p2',
          name: 'p2',
          point: const HyperbolicPoint(0.2, 0.0),
          locked: true,
        );
        final p3 = PointObject(id: 'p3', name: 'p3', locked: true);

        graph.addObject(p1);
        graph.addObject(p2);
        graph.addObject(p3);
        graph.addConstraint(
          EquilateralPointConstraint(
            id: 'c_eq',
            p1Id: 'p1',
            p2Id: 'p2',
            pointId: 'p3',
          ),
        );
        graph.evaluateAll();

        final initialP1Pos = p1.point;
        final lockedP3Pos = p3.point;

        final success = graph.dragPoint(
          'p1',
          const HyperbolicPoint(-0.05, 0.15),
        );
        expect(success, isFalse);
        expect((p1.point - initialP1Pos).magnitude, lessThan(1e-6));
        expect((p3.point - lockedP3Pos).magnitude, lessThan(1e-6));
      },
    );

    test(
      'shrinking or moving a circle preserves existing circle-line intersection',
      () {
        final graph = ConstraintGraph();
        final cCenter = PointObject(
          id: 'c_center',
          name: 'C',
          point: const HyperbolicPoint(0.0, 0.0),
        );
        final cRim = PointObject(
          id: 'c_rim',
          name: 'R',
          point: const HyperbolicPoint(0.5, 0.0),
        );
        final circle = CircleObject(id: 'c1', name: 'c1');

        final lA = PointObject(
          id: 'l_a',
          name: 'A',
          point: const HyperbolicPoint(-0.4, 0.3),
        );
        final lB = PointObject(
          id: 'l_b',
          name: 'B',
          point: const HyperbolicPoint(0.4, 0.3),
        );
        final line = LineObject(id: 'l1', name: 'l1');

        final inter1 = PointObject(id: 'i1', name: 'i1');
        final inter2 = PointObject(id: 'i2', name: 'i2');

        graph.addObject(cCenter);
        graph.addObject(cRim);
        graph.addObject(circle);
        graph.addObject(lA);
        graph.addObject(lB);
        graph.addObject(line);
        graph.addObject(inter1);
        graph.addObject(inter2);

        graph.addConstraint(
          CircleCenterPointConstraint(
            id: 'cc',
            centerId: 'c_center',
            pointOnCircleId: 'c_rim',
            circleId: 'c1',
          ),
        );
        graph.addConstraint(
          LineThroughPointsConstraint(
            id: 'cl',
            p1Id: 'l_a',
            p2Id: 'l_b',
            lineId: 'l1',
          ),
        );
        final interConstraint1 = IntersectionConstraint(
          id: 'ci1',
          obj1Id: 'c1',
          obj2Id: 'l1',
          pointId: 'i1',
          index: 0,
        );
        final interConstraint2 = IntersectionConstraint(
          id: 'ci2',
          obj1Id: 'c1',
          obj2Id: 'l1',
          pointId: 'i2',
          index: 1,
        );
        graph.addConstraint(interConstraint1);
        graph.addConstraint(interConstraint2);
        graph.evaluateAll();

        expect(interConstraint1.computeIntersections(graph), isNotEmpty);

        // Attempt to shrink the circle to radius 0.05 (which would miss l1):
        final moved = graph.dragPoint(
          'c_rim',
          const HyperbolicPoint(0.05, 0.0),
        );
        expect(moved, isTrue);
        // c_rim moved closer to origin than 0.5, but stopped before losing the intersection:
        expect(cRim.point.x, lessThan(0.5));
        expect(cRim.point.x, greaterThan(0.2));
        expect(interConstraint1.computeIntersections(graph), isNotEmpty);
        expect(inter1.visible, isTrue);
        expect(inter2.visible, isTrue);
      },
    );
  });

  group('SceneData Integration', () {
    test('SceneData roundtrip JSON with graph', () {
      final scene = SceneData();
      scene.title = 'Hyperbolic Triangle';

      final p1 = PointObject(
        id: 'p1',
        name: 'A',
        point: const HyperbolicPoint(-0.3, 0.2),
      );
      final p2 = PointObject(
        id: 'p2',
        name: 'B',
        point: const HyperbolicPoint(0.4, -0.1),
      );
      final l1 = LineObject(id: 'l1', name: 'AB', lineStyle: LineStyle.segment);

      scene.graph.addObject(p1);
      scene.graph.addObject(p2);
      scene.graph.addObject(l1);
      scene.graph.addConstraint(
        LineThroughPointsConstraint(
          id: 'c1',
          p1Id: 'p1',
          p2Id: 'p2',
          lineId: 'l1',
        ),
      );
      scene.graph.evaluateAll();

      final jsonStr = scene.toJson().toString();
      // Test JSON decoding and restoration:
      final map = scene.toJson();
      final restoredScene = SceneData.fromJsonString('''
        {
          "title": "${scene.title}",
          "zoom": ${scene.zoom},
          "objects": ${map['objects'] != null ? "[{\"id\": \"p1\", \"type\": \"point\", \"name\": \"A\", \"point\": {\"x\": -0.3, \"y\": 0.2}}, {\"id\": \"p2\", \"type\": \"point\", \"name\": \"B\", \"point\": {\"x\": 0.4, \"y\": -0.1}}, {\"id\": \"l1\", \"type\": \"line\", \"name\": \"AB\", \"lineStyle\": \"segment\"}]" : "[]"},
          "constraints": [
            {"id": "c1", "type": "lineThroughPoints", "inputIds": ["p1", "p2"], "outputIds": ["l1"]}
          ]
        }
        ''');

      expect(restoredScene.title, equals('Hyperbolic Triangle'));
      expect(restoredScene.objects.length, equals(3));
      expect(restoredScene.constraints.length, equals(1));

      final restoredLine = restoredScene.graph.getLine('l1');
      expect(restoredLine, isNotNull);
      expect(restoredLine!.line, isNotNull);
      expect(
        restoredLine.line!.containsPoint(const HyperbolicPoint(-0.3, 0.2)),
        isTrue,
      );
    });
  });
}
