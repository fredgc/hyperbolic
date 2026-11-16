import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:hyperbolic/my_app.dart';
import 'package:hyperbolic/objects/objects.dart';
import 'package:hyperbolic/scene/scene_data.dart';
import 'package:hyperbolic/scene/scene_view.dart';
import 'package:hyperbolic/script.dart';
import 'package:hyperbolic/transform.dart';
import 'package:hyperbolic/tutorials.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Hyperbolic Drawing Tool',
      packageName: 'org.gchouse.hyperbolic',
      version: '1.0.0',
      buildNumber: '4',
      buildSignature: 'signature',
    );
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('Tutorial parser and model unit tests', () {
    test('Parses debug_test.md into structured Tutorial and Steps', () {
      final file = File('assets/dev/tutorials/debug_test.md');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final tutorial = Tutorial.fromMarkdown(content);

      expect(tutorial.title, equals('Debug Tutorial Feature Test'));
      expect(tutorial.steps.length, equals(8));

      // Step 1: Setup & Inline Objects
      final s1 = tutorial.steps[0];
      expect(s1.title, equals('Setup & Inline Objects'));
      expect(s1.directives.any((d) => d is ResetDirective), isTrue);
      expect(s1.directives.any((d) => d is SetupDirective), isTrue);
      expect(s1.directives.any((d) => d is AcknowledgeDirective), isTrue);

      // Step 2: Switch to Point Tool
      final s2 = tutorial.steps[1];
      expect(s2.title, equals('Switch to Point Tool'));
      expect(s2.directives.first, isA<ToolDirective>());
      expect(
        (s2.directives.first as ToolDirective).targetTool,
        equals(HyperbolicTool.point),
      );

      // Step 3: Add a Point
      final s3 = tutorial.steps[2];
      expect(s3.directives.first, isA<AddPointDirective>());

      // Step 4: Select an Object
      final s4 = tutorial.steps[3];
      expect(s4.directives.first, isA<SelectDirective>());
      expect((s4.directives.first as SelectDirective).targetName, equals('A'));

      // Step 5: Drag an Object
      final s5 = tutorial.steps[4];
      expect(s5.directives.first, isA<DragDirective>());
      expect((s5.directives.first as DragDirective).targetName, equals('A'));

      // Step 6: Adjust a Number Slider
      final s6 = tutorial.steps[5];
      expect(s6.directives.first, isA<SliderDirective>());
      expect((s6.directives.first as SliderDirective).targetName, equals('N1'));
      expect((s6.directives.first as SliderDirective).targetValue, equals(2.5));

      // Step 7: Hyperbolic Translation
      final s7 = tutorial.steps[6];
      expect(s7.directives.first, isA<ToolDirective>());
      expect(
        (s7.directives.first as ToolDirective).targetTool,
        equals(HyperbolicTool.moveDisk),
      );
    });

    test('getBuiltInTutorials returns dev tutorials when debug enabled', () {
      final list = getBuiltInTutorials(includeDev: true);
      expect(list.any((t) => t.title == 'Debug Tutorial Feature Test'), isTrue);
    });
  });

  group('TutorialController execution and criteria tests', () {
    test(
      'Steps through Debug Tutorial and verifies criteria satisfaction',
      () async {
        final app = MyApp.fullApp();
        app.manager.driveAccess.isTesting = true;
        await app.initialize();

        final scene = SceneView(app.manager, app.settings, SceneData());
        app.manager.current.scene = scene;
        final file = File('assets/dev/tutorials/debug_test.md');
        final tutorial = Tutorial.fromMarkdown(file.readAsStringSync());

        final controller = TutorialController(scene, tutorial);

        // --- Step 1: Setup & Reset ---
        expect(controller.currentStepIndex, equals(0));
        expect(controller.currentStep?.title, equals('Setup & Inline Objects'));
        // Setup directive ran during step start:
        expect(scene.data.objects.whereType<PointObject>().length, equals(2));
        expect(scene.data.objects.whereType<LineObject>().length, equals(1));
        expect(scene.data.objects.whereType<NumberObject>().length, equals(1));
        expect(controller.isContinueEnabled, isTrue);

        controller.nextStep();

        // --- Step 2: Switch to Point Tool ---
        expect(controller.currentStepIndex, equals(1));
        expect(controller.currentStep?.title, equals('Switch to Point Tool'));
        expect(controller.currentHighlightId, equals('tool.point'));
        expect(controller.isContinueEnabled, isFalse);

        // Switch tool manually
        scene.currentTool.value = HyperbolicTool.point;
        expect(controller.isContinueEnabled, isTrue);

        controller.nextStep();

        // --- Step 3: Add Point C ---
        expect(controller.currentStepIndex, equals(2));
        expect(controller.currentHighlightId, equals('canvas.point'));
        expect(controller.highlightedPoint, isNotNull);
        expect(controller.isContinueEnabled, isFalse);

        // Use "Do it for me"
        expect(controller.canDoItForMe, isTrue);
        controller.doItForMe();
        expect(controller.isContinueEnabled, isTrue);
        expect(scene.data.objects.whereType<PointObject>().length, equals(3));

        controller.nextStep();

        // --- Step 4: Select Object A ---
        expect(controller.currentStepIndex, equals(3));
        expect(controller.currentHighlightId, equals('object.A'));
        expect(controller.isContinueEnabled, isFalse);

        // Select A
        final ptA = scene.data.objects.firstWhere((o) => o.name == 'A');
        scene.selectObject(ptA);
        expect(controller.isContinueEnabled, isTrue);

        controller.nextStep();

        // --- Step 5: Drag Object A ---
        expect(controller.currentStepIndex, equals(4));
        expect(controller.isContinueEnabled, isFalse);
        controller.doItForMe();
        expect(controller.isContinueEnabled, isTrue);

        controller.nextStep();

        // --- Step 6: Adjust Slider N1 ---
        expect(controller.currentStepIndex, equals(5));
        expect(controller.currentHighlightId, equals('slider.N1'));
        expect(controller.isContinueEnabled, isFalse);

        final n1 = scene.data.objects.whereType<NumberObject>().firstWhere(
          (n) => n.name == 'N1',
        );
        n1.value = 2.5;
        scene.requestRepaintScene();
        expect(controller.isContinueEnabled, isTrue);

        controller.nextStep();

        // --- Step 7: Hyperbolic Translation tool ---
        expect(controller.currentStepIndex, equals(6));
        expect(controller.currentHighlightId, equals('tool.moveDisk'));
        controller.doItForMe();
        expect(scene.currentTool.value, equals(HyperbolicTool.moveDisk));
        expect(controller.isContinueEnabled, isTrue);

        controller.nextStep();

        // --- Step 8: Complete ---
        expect(controller.currentStepIndex, equals(7));
        expect(controller.isContinueEnabled, isTrue);

        controller.nextStep();
        expect(controller.isCompleted, isTrue);

        controller.dispose();
      },
    );
  });
}
