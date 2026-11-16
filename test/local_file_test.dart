import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:hyperbolic/constraints/constraints.dart';
import 'package:hyperbolic/file_holder.dart';
import 'package:hyperbolic/file_manager.dart';
import 'package:hyperbolic/local_file.dart';
import 'package:hyperbolic/my_app.dart';
import 'package:hyperbolic/objects/objects.dart';
import 'package:hyperbolic/scene.dart';
import 'package:hyperbolic/transform.dart';
import 'package:hyperbolic/upload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    LocalFileHolder.ids = [];
    LocalFileHolder.titles = {};
  });

  group('LocalFileHolder unit tests', () {
    test('Initialization with empty prefs', () async {
      await LocalFileHolder.initialize();
      expect(LocalFileHolder.ids, isEmpty);
      expect(LocalFileHolder.titles, isEmpty);
    });

    test('makeNew allocates sequential unique IDs', () {
      final file1 = LocalFileHolder.makeNew();
      expect(file1.isNew, isTrue);
      expect(LocalFileHolder.ids, contains(file1.id));
      expect(LocalFileHolder.titles[file1.id], equals('new local file'));

      final file2 = LocalFileHolder.makeNew();
      expect(file2.id, isNot(equals(file1.id)));
      expect(LocalFileHolder.ids.length, equals(2));
    });

    test('saveData and loadData persists hyperbolic scene JSON', () async {
      await LocalFileHolder.initialize();
      final holder = LocalFileHolder.makeNew();
      holder.title = 'Hyperbolic Triangle';

      // Create a scene with points and geodesic
      final scene = SceneData();
      final p1 = PointObject(
        id: 'p1',
        name: 'A',
        point: const HyperbolicPoint(0.2, 0.3),
      );
      final p2 = PointObject(
        id: 'p2',
        name: 'B',
        point: const HyperbolicPoint(-0.4, 0.1),
      );
      scene.graph.addObject(p1);
      scene.graph.addObject(p2);
      final line = LineObject(
        id: 'l1',
        name: 'AB',
        p1: p1.point,
        p2: p2.point,
        lineStyle: LineStyle.segment,
      );
      scene.graph.addObject(line);
      scene.graph.addConstraint(
        LineThroughPointsConstraint(
          id: 'c1',
          p1Id: 'p1',
          p2Id: 'p2',
          lineId: 'l1',
        ),
      );

      final app = MyApp.fullApp();
      final jsonString = jsonEncode(scene.toJson());

      // Save data
      final saved = await holder.saveData(jsonString, app.manager);
      expect(saved, isTrue);

      // Verify titles persisted
      expect(LocalFileHolder.titles[holder.id], equals('Hyperbolic Triangle'));

      // Load data
      final loadedString = await holder.loadData(app.manager);
      final restoredScene = SceneData.fromJsonString(loadedString);

      expect(restoredScene.objects.length, equals(3));
      expect(restoredScene.objects.whereType<PointObject>().length, equals(2));
      expect(restoredScene.objects.whereType<LineObject>().length, equals(1));
    });

    test('reorder changes sequence of local files', () async {
      final f1 = LocalFileHolder.makeNew();
      final f2 = LocalFileHolder.makeNew();
      final f3 = LocalFileHolder.makeNew();

      expect(LocalFileHolder.ids, equals([f1.id, f2.id, f3.id]));

      await LocalFileHolder.reorder(0, 3);
      expect(LocalFileHolder.ids, equals([f2.id, f3.id, f1.id]));
    });

    test('deleteFile removes local file and its data', () async {
      final app = MyApp.fullApp();
      final f1 = LocalFileHolder.makeNew();
      await f1.saveData('{"test": 123}', app.manager);
      expect(LocalFileHolder.ids, contains(f1.id));

      await LocalFileHolder.deleteFile(f1.id);
      expect(LocalFileHolder.ids, isNot(contains(f1.id)));
      expect(LocalFileHolder.titles.containsKey(f1.id), isFalse);

      final loaded = await f1.loadData(app.manager);
      expect(loaded, equals('local-data-not-found'));
    });

    test('Properties and descriptions', () {
      final holder = LocalFileHolder('xyz');
      holder.title = 'Poincaré Mosaic';
      expect(holder.type, equals('local'));
      expect(holder.path, equals('/scene?local=xyz'));
      expect(holder.skipRecent, isFalse);
      expect(holder.userDescription(), equals('Poincaré Mosaic (local xyz)'));
    });
  });

  group('UploadHolder unit tests', () {
    test('Properties and serialization', () {
      final holder = UploadHolder('scene.json');
      holder.title = 'Downloaded Diagram';
      expect(holder.type, equals('download'));
      expect(holder.filename, equals('scene.json'));
      expect(holder.skipRecent, isFalse);
      expect(
        holder.userDescription(),
        equals('Downloaded Diagram (scene.json)'),
      );
    });

    test('loadData returns cached data when present', () async {
      final app = MyApp.fullApp();
      final holder = UploadHolder('test.json');
      holder.data = '{"sample": "data"}';

      final result = await holder.loadData(app.manager);
      expect(result, equals('{"sample": "data"}'));
      // Cached data is cleared after first consumption
      expect(holder.data, isEmpty);
    });
  });
}
