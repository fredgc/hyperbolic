import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:hyperbolic/edit.dart';
import 'package:hyperbolic/file_manager.dart';
import 'package:hyperbolic/objects/objects.dart';
import 'package:hyperbolic/scene/scene_data.dart';
import 'package:hyperbolic/scene/scene_view.dart';
import 'package:hyperbolic/settings.dart';
import 'package:hyperbolic/transform.dart';

void _applyRandomEdit(SceneView scene, math.Random rng, int step) {
  final points = scene.data.objects.whereType<PointObject>().toList();
  final allObjects = scene.data.objects.toList();

  // If fewer than 2 points exist, always add a free point
  final action = points.length < 2 ? 0 : rng.nextInt(8);

  switch (action) {
    case 0:
      // Add free point inside disk
      final r = rng.nextDouble() * 0.75;
      final theta = rng.nextDouble() * 2 * math.pi;
      scene.createFreePoint(
        HyperbolicPoint(r * math.cos(theta), r * math.sin(theta)),
      );
      break;
    case 1:
      // Add line, segment, or ray between two distinct points
      final p1 = points[rng.nextInt(points.length)];
      final others = points.where((p) => p.id != p1.id).toList();
      final p2 = others[rng.nextInt(others.length)];
      final styles = LineStyle.values;
      scene.createLine(p1.id, p2.id, style: styles[rng.nextInt(styles.length)]);
      break;
    case 2:
      // Add circle from center and circumference point
      final p1 = points[rng.nextInt(points.length)];
      final others = points.where((p) => p.id != p1.id).toList();
      final p2 = others[rng.nextInt(others.length)];
      scene.createCircle(p1.id, p2.id);
      break;
    case 3:
      // Add midpoint
      final p1 = points[rng.nextInt(points.length)];
      final others = points.where((p) => p.id != p1.id).toList();
      final p2 = others[rng.nextInt(others.length)];
      scene.createMidpoint(p1.id, p2.id);
      break;
    case 4:
      // Add perpendicular bisector
      final p1 = points[rng.nextInt(points.length)];
      final others = points.where((p) => p.id != p1.id).toList();
      final p2 = others[rng.nextInt(others.length)];
      scene.createPerpendicularBisector(p1.id, p2.id);
      break;
    case 5:
      // Add distance measurement
      final p1 = points[rng.nextInt(points.length)];
      final others = points.where((p) => p.id != p1.id).toList();
      final p2 = others[rng.nextInt(others.length)];
      scene.createDistanceMeasurement(p1.id, p2.id);
      break;
    case 6:
      // Rename a random object
      final obj = allObjects[rng.nextInt(allObjects.length)];
      final oldName = obj.name;
      final newName = 'name_${step}_${rng.nextInt(100)}';
      scene.undoManager.add(
        Change<String>('Rename $oldName', oldName, newName, (v) {
          obj.name = v;
        }),
      );
      break;
    case 7:
      // Toggle lock on a random object
      scene.selected = allObjects[rng.nextInt(allObjects.length)];
      scene.toggleLockSelected();
      break;
  }
}

void _runRandomUndoRedoSequence(int seed) {
  final rng = math.Random(seed);
  final settings = Settings();
  final fileManager = FileManager(settings);
  final scene = SceneView(fileManager, settings, SceneData());

  const numEdits = 15;
  final snapshots = <String>[jsonEncode(scene.toJson())];

  for (int i = 0; i < numEdits; i++) {
    _applyRandomEdit(scene, rng, i);
    snapshots.add(jsonEncode(scene.toJson()));
  }

  expect(scene.undoManager.undoList.length, equals(numEdits));
  expect(scene.undoManager.redoList.isEmpty, isTrue);

  // Undo back to cut1
  final int cut1 = rng.nextInt(numEdits);
  final int undoCount1 = numEdits - cut1;
  for (int i = 0; i < undoCount1; i++) {
    scene.undoManager.undo();
  }
  expect(scene.undoManager.undoList.length, equals(cut1));
  expect(scene.undoManager.redoList.length, equals(undoCount1));
  expect(jsonEncode(scene.toJson()), equals(snapshots[cut1]));

  // Redo forward by redoCount to cut2
  final int redoCount = undoCount1 == 0 ? 0 : rng.nextInt(undoCount1 + 1);
  final int cut2 = cut1 + redoCount;
  for (int i = 0; i < redoCount; i++) {
    scene.undoManager.redo();
  }
  expect(scene.undoManager.undoList.length, equals(cut2));
  expect(scene.undoManager.redoList.length, equals(undoCount1 - redoCount));
  expect(jsonEncode(scene.toJson()), equals(snapshots[cut2]));

  // Undo back to cut3
  final int cut3 = cut2 == 0 ? 0 : rng.nextInt(cut2);
  final int undoCount2 = cut2 - cut3;
  for (int i = 0; i < undoCount2; i++) {
    scene.undoManager.undo();
  }
  expect(scene.undoManager.undoList.length, equals(cut3));
  expect(
    scene.undoManager.redoList.length,
    equals(undoCount1 - redoCount + undoCount2),
  );
  expect(jsonEncode(scene.toJson()), equals(snapshots[cut3]));
}

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

  group('MyUndoManager unit tests', () {
    test('add, undo, redo, and unsaved tracking', () {
      final manager = MyUndoManager();
      int value = 0;

      expect(manager.isUnsaved, false);
      expect(manager.undoList.isEmpty, true);
      expect(manager.redoList.isEmpty, true);

      // Perform an action
      manager.add(Change<int>('increment', value, 10, (v) => value = v));
      expect(value, 10);
      expect(manager.isUnsaved, true);
      expect(manager.undoList.length, 1);

      // Mark saved
      manager.markSaved();
      expect(manager.isUnsaved, false);

      // Another action
      manager.add(Change<int>('increment', value, 20, (v) => value = v));
      expect(value, 20);
      expect(manager.isUnsaved, true);

      // Undo back to saved state
      manager.undo();
      expect(value, 10);
      expect(manager.isUnsaved, false);

      // Redo
      manager.redo();
      expect(value, 20);
      expect(manager.isUnsaved, true);

      // Undo twice
      manager.undo();
      manager.undo();
      expect(value, 0);
      expect(manager.isUnsaved, true);

      // Redo back to saved state
      manager.redo();
      expect(value, 10);
      expect(manager.isUnsaved, false);
    });

    test('UndoCallback executes correctly', () {
      final manager = MyUndoManager();
      String status = 'idle';

      manager.add(
        UndoCallback(
          'setStatus',
          undoCallback: () => status = 'idle',
          redoCallback: () => status = 'running',
        ),
      );

      expect(status, 'running');
      manager.undo();
      expect(status, 'idle');
      manager.redo();
      expect(status, 'running');
    });
  });

  group('Monte Carlo undo-redo-undo sequences', () {
    for (int i = 0; i < 2; i++) {
      final seed = 1000 + i;
      test('random undo-redo-undo sequence (seed $seed)', () {
        _runRandomUndoRedoSequence(seed);
      });
    }

    for (int i = 0; i < 48; i++) {
      final seed = 2000 + i;
      test('stress random undo-redo-undo sequence (seed $seed)', () {
        _runRandomUndoRedoSequence(seed);
      }, tags: 'stress');
    }
  });
}
