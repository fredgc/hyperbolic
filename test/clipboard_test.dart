import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hyperbolic/file_holder.dart';
import 'package:hyperbolic/file_manager.dart';
import 'package:hyperbolic/scene.dart';
import 'package:hyperbolic/settings.dart';
import 'package:hyperbolic/upload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Clipboard URL save and load', () {
    String? clipboardText;

    setUp(() {
      clipboardText = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboardText = (call.arguments as Map)['text'] as String?;
              return null;
            }
            if (call.method == 'Clipboard.getData') {
              return <String, dynamic>{'text': clipboardText};
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('ClipboardHolder saves JSON as URL and loads it back cleanly', () async {
      final settings = Settings();
      final manager = FileManager(settings);
      final saveHolder = ClipboardHolder(true);

      final sampleScene = SceneData();
      sampleScene.title = "Hyperbolic Triangle";
      final sampleJson = jsonEncode(sampleScene);

      final saved = await saveHolder.saveData(sampleJson, manager);
      expect(saved, isTrue);
      expect(clipboardText, isNotNull);
      expect(clipboardText!, contains('/scene?json='));

      clipboardText =
          'https://hyperbolic.gchouse.org/scene?json=${Uri.encodeQueryComponent(sampleJson)}';
      final loadHolder = ClipboardHolder(false);
      final loadedJson = await loadHolder.loadData(manager);
      final loadedScene = SceneData.fromJsonString(loadedJson);
      expect(loadedScene.title, equals("Hyperbolic Triangle"));
    });

    test('ClipboardHolder loads hash-routed URL (#/scene?json=...)', () async {
      final settings = Settings();
      final manager = FileManager(settings);

      final sampleScene = SceneData();
      sampleScene.title = "Poincare Disk Geodesic";
      final sampleJson = jsonEncode(sampleScene);

      clipboardText =
          'https://hyperbolic.gchouse.org/#/scene?json=${Uri.encodeQueryComponent(sampleJson)}';
      final loadHolder = ClipboardHolder(false);
      final loadedJson = await loadHolder.loadData(manager);
      final loadedScene = SceneData.fromJsonString(loadedJson);
      expect(loadedScene.title, equals("Poincare Disk Geodesic"));
    });
  });
}
