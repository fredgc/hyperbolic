import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:hyperbolic/constraints/constraints.dart';
import 'package:hyperbolic/objects/objects.dart';
import 'package:hyperbolic/scene/scene_data.dart';
import 'package:hyperbolic/scene/scene_view.dart';
import 'package:hyperbolic/settings.dart';
import 'package:hyperbolic/transform.dart';
import 'package:hyperbolic/file_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Hyperbolic Drawing Tool',
      packageName: 'org.gchouse.hyperbolic',
      version: '1.0.0',
      buildNumber: '9',
      buildSignature: 'signature',
    );
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('MidpointConstraint tests', () {
    test('Calculates exact hyperbolic midpoint and updates reactively', () {
      final graph = ConstraintGraph();
      final p1 = PointObject(
        id: 'p1',
        name: 'A',
        point: const HyperbolicPoint(0.0, 0.0),
      );
      final p2 = PointObject(
        id: 'p2',
        name: 'B',
        point: const HyperbolicPoint(0.6, 0.0),
      );
      final mid = PointObject(
        id: 'm',
        name: 'M',
        point: const HyperbolicPoint(0.0, 0.0),
      );
      final cMid = MidpointConstraint(
        id: 'c_mid',
        p1Id: 'p1',
        p2Id: 'p2',
        pointId: 'm',
      );

      graph.addObject(p1);
      graph.addObject(p2);
      graph.addObject(mid);
      graph.addConstraint(cMid);

      graph.evaluateAll();

      final double totalDist = p1.point.hyperbolicDistance(p2.point);
      final double d1 = p1.point.hyperbolicDistance(mid.point);
      final double d2 = mid.point.hyperbolicDistance(p2.point);

      expect(d1, closeTo(totalDist / 2.0, 1e-6));
      expect(d2, closeTo(totalDist / 2.0, 1e-6));

      // Move P2 and re-evaluate
      p2.point = const HyperbolicPoint(0.0, 0.8);
      graph.evaluateAll();

      final double newTotal = p1.point.hyperbolicDistance(p2.point);
      expect(
        p1.point.hyperbolicDistance(mid.point),
        closeTo(newTotal / 2.0, 1e-6),
      );
      expect(
        mid.point.hyperbolicDistance(p2.point),
        closeTo(newTotal / 2.0, 1e-6),
      );
    });
  });

  group('PerpendicularLineConstraint tests', () {
    test('Constructs perpendicular geodesic through point', () {
      final graph = ConstraintGraph();
      // Horizontal diameter: line through (-0.5, 0) and (0.5, 0)
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
      final baseLine = LineObject(id: 'base', name: 'L');
      final cLine = LineThroughPointsConstraint(
        id: 'c_base',
        p1Id: 'p1',
        p2Id: 'p2',
        lineId: 'base',
      );

      final pFoot = PointObject(
        id: 'pf',
        name: 'O',
        point: const HyperbolicPoint(0.0, 0.0),
      );
      final perpLine = LineObject(id: 'perp', name: 'L_perp');
      final cPerp = PerpendicularLineConstraint(
        id: 'c_perp',
        baseLineId: 'base',
        pointId: 'pf',
        lineId: 'perp',
      );

      graph.addObject(p1);
      graph.addObject(p2);
      graph.addObject(baseLine);
      graph.addObject(pFoot);
      graph.addObject(perpLine);
      graph.addConstraint(cLine);
      graph.addConstraint(cPerp);

      graph.evaluateAll();

      expect(perpLine.line, isNotNull);
      // Perpendicular to horizontal line at origin should be vertical diameter:
      expect(perpLine.line!.isDiameter, isTrue);
      expect(math.cos(perpLine.line!.diameterAngle).abs(), closeTo(0.0, 1e-4));
    });
  });

  group('PerpendicularBisectorConstraint tests', () {
    test('Constructs perpendicular bisector of segment', () {
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
      final bisector = LineObject(id: 'bisect', name: 'L_bisect');
      final cBisect = PerpendicularBisectorConstraint(
        id: 'c_bisect',
        p1Id: 'p1',
        p2Id: 'p2',
        lineId: 'bisect',
      );

      graph.addObject(p1);
      graph.addObject(p2);
      graph.addObject(bisector);
      graph.addConstraint(cBisect);

      graph.evaluateAll();

      expect(bisector.line, isNotNull);
      expect(bisector.line!.isDiameter, isTrue);
      expect(math.cos(bisector.line!.diameterAngle).abs(), closeTo(0.0, 1e-4));
    });
  });

  group('AngleBisectorConstraint tests', () {
    test('Constructs angle bisector ray between two geodesics', () {
      final graph = ConstraintGraph();
      final vertex = PointObject(
        id: 'v',
        name: 'V',
        point: const HyperbolicPoint(0.0, 0.0),
      );
      final p1 = PointObject(
        id: 'p1',
        name: 'A',
        point: const HyperbolicPoint(0.5, 0.0), // 0 rad
      );
      final p2 = PointObject(
        id: 'p2',
        name: 'B',
        point: const HyperbolicPoint(0.0, 0.5), // pi/2 rad
      );
      final bisector = LineObject(
        id: 'bisect',
        name: 'L_ang_bisect',
        lineStyle: LineStyle.ray,
      );
      final cAng = AngleBisectorConstraint(
        id: 'c_ang',
        p1Id: 'p1',
        vertexId: 'v',
        p2Id: 'p2',
        lineId: 'bisect',
      );

      graph.addObject(vertex);
      graph.addObject(p1);
      graph.addObject(p2);
      graph.addObject(bisector);
      graph.addConstraint(cAng);

      graph.evaluateAll();

      expect(bisector.line, isNotNull);
      // At origin, angle bisector between 0 and pi/2 is pi/4:
      expect(bisector.line!.diameterAngle, closeTo(math.pi / 4, 1e-4));
    });
  });

  group('CompassCircleConstraint tests', () {
    test('Circle radius matches distance between reference points', () {
      final graph = ConstraintGraph();
      final a = PointObject(
        id: 'a',
        name: 'A',
        point: const HyperbolicPoint(0.1, 0.1),
      );
      final b = PointObject(
        id: 'b',
        name: 'B',
        point: const HyperbolicPoint(0.5, 0.2),
      );
      final center = PointObject(
        id: 'c_pt',
        name: 'C',
        point: const HyperbolicPoint(-0.2, 0.3),
      );
      final circ = CircleObject(id: 'circ', name: 'CircleCompass');
      final cComp = CompassCircleConstraint(
        id: 'c_comp',
        centerId: 'c_pt',
        p1Id: 'a',
        p2Id: 'b',
        circleId: 'circ',
      );

      graph.addObject(a);
      graph.addObject(b);
      graph.addObject(center);
      graph.addObject(circ);
      graph.addConstraint(cComp);

      graph.evaluateAll();

      expect(circ.circle, isNotNull);
      final double expectedRadius = a.point.hyperbolicDistance(b.point);
      expect(circ.circle!.hyperbolicRadius, closeTo(expectedRadius, 1e-6));
      expect(circ.circle!.hyperbolicCenter, equals(center.point));

      // Move B, radius updates automatically:
      b.point = const HyperbolicPoint(0.2, 0.6);
      graph.evaluateAll();
      final double updatedRadius = a.point.hyperbolicDistance(b.point);
      expect(circ.circle!.hyperbolicRadius, closeTo(updatedRadius, 1e-6));
    });
  });

  group('Equilateral Triangle construction tests', () {
    test('Constructs equilateral triangle with 3 equal hyperbolic sides', () {
      final graph = ConstraintGraph();
      final p1 = PointObject(
        id: 'p1',
        name: 'A',
        point: const HyperbolicPoint(-0.2, 0.0),
      );
      final p2 = PointObject(
        id: 'p2',
        name: 'B',
        point: const HyperbolicPoint(0.2, 0.0),
      );
      final p3 = PointObject(
        id: 'p3',
        name: 'C',
        point: const HyperbolicPoint(0.0, 0.0),
      );
      final cEq = EquilateralPointConstraint(
        id: 'c_eq',
        p1Id: 'p1',
        p2Id: 'p2',
        pointId: 'p3',
      );

      graph.addObject(p1);
      graph.addObject(p2);
      graph.addObject(p3);
      graph.addConstraint(cEq);

      graph.evaluateAll();

      final double sideAB = p1.point.hyperbolicDistance(p2.point);
      final double sideAC = p1.point.hyperbolicDistance(p3.point);
      final double sideBC = p2.point.hyperbolicDistance(p3.point);

      expect(sideAC, closeTo(sideAB, 1e-5));
      expect(sideBC, closeTo(sideAB, 1e-5));
    });
  });

  group('SceneView interactive constructors and undo/redo', () {
    test(
      'Creates midpoint, perpendicular, and equilateral triangle via SceneView',
      () async {
        final settings = Settings();
        final fileManager = FileManager(settings);
        final scene = SceneView(fileManager, settings, SceneData());

        // Create two points
        final a = scene.createFreePoint(const HyperbolicPoint(-0.3, 0.1));
        final b = scene.createFreePoint(const HyperbolicPoint(0.3, 0.1));

        // 1. Midpoint
        final m = scene.createMidpoint(a.id, b.id);
        expect(scene.data.objects.contains(m), isTrue);
        expect(
          a.point.hyperbolicDistance(m.point),
          closeTo(b.point.hyperbolicDistance(m.point), 1e-5),
        );

        // Undo midpoint
        scene.undoManager.undo();
        expect(scene.data.objects.any((o) => o.id == m.id), isFalse);

        // Redo midpoint
        scene.undoManager.redo();
        expect(scene.data.objects.any((o) => o.id == m.id), isTrue);

        // 2. Perpendicular Bisector
        final bisect = scene.createPerpendicularBisector(a.id, b.id);
        expect(scene.data.objects.contains(bisect), isTrue);

        // 3. Equilateral triangle (creates base segment s1 + sides s2, s3)
        final linesBefore = scene.data.objects.whereType<LineObject>().length;
        final c = scene.createEquilateralTriangle(a.id, b.id);
        expect(scene.data.objects.contains(c), isTrue);
        expect(
          scene.data.objects.whereType<LineObject>().length,
          equals(linesBefore + 3),
        );
        final double dAB = a.point.hyperbolicDistance(b.point);
        final double dAC = a.point.hyperbolicDistance(c.point);
        final double dBC = b.point.hyperbolicDistance(c.point);
        expect(dAC, closeTo(dAB, 1e-5));
        expect(dBC, closeTo(dAB, 1e-5));

        // Undo equilateral triangle (removes C and all 3 edges in single step)
        scene.undoManager.undo();
        expect(scene.data.objects.any((o) => o.id == c.id), isFalse);
        expect(
          scene.data.objects.whereType<LineObject>().length,
          equals(linesBefore),
        );

        // If base segment already exists, it does not create a duplicate base segment
        final baseSeg = scene.createLine(a.id, b.id, style: LineStyle.segment);
        expect(scene.data.objects.contains(baseSeg), isTrue);
        final linesWithBase = scene.data.objects.whereType<LineObject>().length;
        final c2 = scene.createEquilateralTriangle(a.id, b.id);
        expect(scene.data.objects.contains(c2), isTrue);
        expect(
          scene.data.objects.whereType<LineObject>().length,
          equals(linesWithBase + 2),
        );

        // Undo equilateral triangle preserves existing base segment
        scene.undoManager.undo();
        expect(scene.data.objects.contains(baseSeg), isTrue);
        expect(
          scene.data.objects.whereType<LineObject>().length,
          equals(linesWithBase),
        );
      },
    );
  });
}
