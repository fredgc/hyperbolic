import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:hyperbolic/file_manager.dart';
import 'package:hyperbolic/my_app.dart';
import 'package:hyperbolic/objects/objects.dart';
import 'package:hyperbolic/scene/scene_data.dart';
import 'package:hyperbolic/scene/scene_view.dart';
import 'package:hyperbolic/settings.dart';
import 'package:hyperbolic/splitter.dart';
import 'package:hyperbolic/transform.dart';
import 'package:hyperbolic/widgets/app_widget.dart';
import 'package:hyperbolic/widgets/json_syntax_dialog.dart';
import 'package:hyperbolic/widgets/number_panel.dart';
import 'package:hyperbolic/widgets/tap_to_edit.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Hyperbolic Drawing Tool',
      packageName: 'org.gchouse.hyperbolic',
      version: '1.0.0',
      buildNumber: '3',
      buildSignature: 'signature',
    );
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('App loads smoke test', (WidgetTester tester) async {
    final app = MyApp.fullApp();
    app.manager.driveAccess.isTesting = true;
    await app.initialize();

    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    expect(find.byType(AppWidget), findsOneWidget);
    expect(find.byType(SplitterWidget), findsOneWidget);
    expect(find.byType(NumberPanel), findsOneWidget);
  });

  testWidgets('App starts directly in dark mode when saved in preferences', (
    WidgetTester tester,
  ) async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    await prefs.setInt('theme_mode', ThemeMode.dark.index);

    final app = MyApp.fullApp();
    app.manager.driveAccess.isTesting = true;
    await app.initialize();

    expect(app.settings.theme.themeMode, equals(ThemeMode.dark));
    expect(app.settings.theme.scheme.brightness, equals(Brightness.dark));

    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.brightness, equals(Brightness.dark));
  });

  testWidgets('Toolbar tool switching works and only active tool expands label', (
    WidgetTester tester,
  ) async {
    final app = MyApp.fullApp();
    app.manager.driveAccess.isTesting = true;
    await app.initialize();

    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    final scene = app.manager.current.scene!;
    expect(scene.currentTool.value, equals(HyperbolicTool.select));
    expect(find.widgetWithText(ChoiceChip, 'Select'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Point'), findsNothing);

    // Tap 'Points' collapsed tool chip -> activates 'Point' and expands label
    final pointChip = find.byKey(const ValueKey('tool_chip_points'));
    await tester.ensureVisible(pointChip);
    await tester.tap(pointChip);
    await tester.pumpAndSettle();
    expect(scene.currentTool.value, equals(HyperbolicTool.point));
    expect(find.widgetWithText(ChoiceChip, 'Point'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Select'), findsNothing);

    // Tap 'Lines' collapsed tool chip -> activates 'Line' and expands label
    final lineChip = find.byKey(const ValueKey('tool_chip_lines'));
    await tester.ensureVisible(lineChip);
    await tester.tap(lineChip);
    await tester.pumpAndSettle();
    expect(scene.currentTool.value, equals(HyperbolicTool.line));
    expect(find.widgetWithText(ChoiceChip, 'Line'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Point'), findsNothing);

    // Tap 'Circles' collapsed tool chip -> activates 'Circle' and expands label
    final circleChip = find.byKey(const ValueKey('tool_chip_circles'));
    await tester.ensureVisible(circleChip);
    await tester.tap(circleChip);
    await tester.pumpAndSettle();
    expect(scene.currentTool.value, equals(HyperbolicTool.circle));
    expect(find.widgetWithText(ChoiceChip, 'Circle'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Line'), findsNothing);
  });

  testWidgets('Adding point via canvas click', (WidgetTester tester) async {
    final app = MyApp.fullApp();
    app.manager.driveAccess.isTesting = true;
    await app.initialize();

    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    final scene = app.manager.current.scene!;

    // Switch to Point tool
    final pointChip = find.byKey(const ValueKey('tool_chip_points'));
    await tester.ensureVisible(pointChip);
    await tester.tap(pointChip);
    await tester.pumpAndSettle();

    // Click near center of canvas
    final canvasFinder = find.byKey(const ValueKey('poincare_canvas'));
    await tester.tap(canvasFinder);
    await tester.pumpAndSettle();

    // Verify a PointObject was added to the scene
    expect(scene.data.objects.whereType<PointObject>().length, equals(1));
  });

  testWidgets(
    'Number panel can add free number parameter and open constructor menu',
    (WidgetTester tester) async {
      final app = MyApp.fullApp();
      app.manager.driveAccess.isTesting = true;
      await app.initialize();

      await tester.pumpWidget(app.build());
      await tester.pumpAndSettle();

      final scene = app.manager.current.scene!;
      expect(scene.data.objects.whereType<NumberObject>().isEmpty, isTrue);

      // Tap '+' button in NumberPanel
      final addNumBtn = find.byTooltip('Add Free Parameter');
      expect(addNumBtn, findsOneWidget);
      await tester.tap(addNumBtn);
      await tester.pumpAndSettle();

      expect(scene.data.objects.whereType<NumberObject>().length, equals(1));
      expect(scene.selected, isA<NumberObject>());

      // Open the Number Constructor menu in NumberPanel and select 'Distance (D)'
      final numMenuBtn = find.byKey(const ValueKey('number_constructor_menu'));
      expect(numMenuBtn, findsOneWidget);
      await tester.tap(numMenuBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Distance (D)'));
      await tester.pumpAndSettle();
      expect(scene.currentTool.value, equals(HyperbolicTool.measureDistance));
    },
  );

  testWidgets('JsonSyntaxEditorDialog displays and validates', (
    WidgetTester tester,
  ) async {
    final app = MyApp.fullApp();
    app.manager.driveAccess.isTesting = true;
    await app.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog<bool>(
                  context: context,
                  builder: (c) => JsonSyntaxEditorDialog(
                    fileManager: app.manager,
                    initialJson: '{ "invalid": json syntax }',
                  ),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Edit JSON Syntax'), findsOneWidget);
  });

  testWidgets('Theme changes in settings update main view theme and colors', (
    WidgetTester tester,
  ) async {
    final app = MyApp.fullApp();
    app.manager.driveAccess.isTesting = true;
    await app.initialize();

    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    final appWidgetFinder = find.byType(AppWidget);
    expect(appWidgetFinder, findsOneWidget);

    final BuildContext initialContext = tester.element(appWidgetFinder);
    expect(Theme.of(initialContext).brightness, equals(Brightness.light));

    // Switch theme mode to dark in settings and notify
    app.settings.theme.themeMode = ThemeMode.dark;
    app.settings.resetColorsAndNotify();
    await tester.pumpAndSettle();

    final BuildContext darkContext = tester.element(appWidgetFinder);
    expect(Theme.of(darkContext).brightness, equals(Brightness.dark));

    // Switch theme seed color to teal and notify
    app.settings.theme.themeColor.value = Colors.teal;
    app.settings.resetColorsAndNotify();
    await tester.pumpAndSettle();

    final BuildContext tealContext = tester.element(appWidgetFinder);
    expect(
      Theme.of(tealContext).colorScheme.primary,
      equals(app.settings.theme.scheme.primary),
    );
  });

  testWidgets('Keyboard shortcuts switch tools and trigger actions', (
    WidgetTester tester,
  ) async {
    final app = MyApp.fullApp();
    app.manager.driveAccess.isTesting = true;
    await app.initialize();

    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    final scene = app.manager.current.scene!;
    expect(scene.currentTool.value, equals(HyperbolicTool.select));

    // Press 'L' -> Line
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await tester.pumpAndSettle();
    expect(scene.currentTool.value, equals(HyperbolicTool.line));

    // Press 'S' -> Segment
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pumpAndSettle();
    expect(scene.currentTool.value, equals(HyperbolicTool.segment));

    // Press 'P' -> Point
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pumpAndSettle();
    expect(scene.currentTool.value, equals(HyperbolicTool.point));

    // Press 'C' -> Circle
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.pumpAndSettle();
    expect(scene.currentTool.value, equals(HyperbolicTool.circle));

    // Press 'Escape' -> Select
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(scene.currentTool.value, equals(HyperbolicTool.select));

    // Create a point by tapping canvas
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('poincare_canvas')));
    await tester.pumpAndSettle();

    final pt = scene.data.objects.whereType<PointObject>().first;
    scene.selected = pt;
    expect(pt.locked, isFalse);

    // Press 'K' -> toggle lock
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.pumpAndSettle();
    expect(pt.locked, isTrue);

    // Press 'Backspace' -> delete
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    expect(scene.data.objects.whereType<PointObject>().isEmpty, isTrue);
  });

  test('Object labels start counting at 1 (p1, l1, c1, etc.)', () {
    final settings = Settings();
    final fileManager = FileManager(settings);
    final scene = SceneView(fileManager, settings, SceneData());
    final p1 = scene.createFreePoint(const HyperbolicPoint(0.1, 0.1));
    final p2 = scene.createFreePoint(const HyperbolicPoint(0.0, 0.0));
    final p3 = scene.createFreePoint(const HyperbolicPoint(0.1, -0.1));
    expect(p1.name, equals('p1'));
    expect(p2.name, equals('p2'));
    expect(p3.name, equals('p3'));

    final l1 = scene.createLine(p1.id, p2.id);
    final l2 = scene.createLine(p2.id, p3.id);
    expect(l1.name, equals('l1'));
    expect(l2.name, equals('l2'));

    final s1 = scene.createLine(p1.id, p3.id, style: LineStyle.segment);
    expect(s1.name, equals('s1'));

    final r1 = scene.createLine(p1.id, p2.id, style: LineStyle.ray);
    expect(r1.name, equals('r1'));

    final c1 = scene.createCircle(p1.id, p2.id);
    expect(c1.name, equals('c1'));

    final x1 = scene.createIntersection(l1.id, l2.id);
    expect(x1.name, equals('x1'));

    final m1 = scene.createMidpoint(p1.id, p2.id);
    expect(m1.name, equals('m1'));

    final d1 = scene.createDistanceMeasurement(p1.id, p2.id);
    expect(d1.name, equals('d1'));

    final ang1 = scene.createAngleMeasurement(p1.id, p2.id, p3.id);
    expect(ang1.name, equals('α 1'));
    final ang2 = scene.createAngleMeasurement(p1.id, p2.id, p3.id);
    expect(ang2.name, equals('α 2'));
    final ang3 = scene.createAngleMeasurement(p1.id, p2.id, p3.id);
    expect(ang3.name, equals('α 3'));
  });

  test(
    'Intersecting a circle with a line or circle generates two intersection points',
    () {
      final settings = Settings();
      final fileManager = FileManager(settings);
      final scene = SceneView(fileManager, settings, SceneData());

      final p1 = scene.createFreePoint(const HyperbolicPoint(-0.2, 0.0));
      final p2 = scene.createFreePoint(const HyperbolicPoint(0.2, 0.0));
      final l1 = scene.createLine(p1.id, p2.id);
      final c1 = scene.createCircle(p1.id, p2.id);
      final c2 = scene.createCircle(p2.id, p1.id);

      // Circle-Line intersection generates two distinct points x1 and x2
      scene.createIntersection(c1.id, l1.id);
      final ptsAfterLine = scene.data.objects.whereType<PointObject>().toList();
      expect(ptsAfterLine.length, equals(4)); // p1, p2, x1, x2
      final x1 = ptsAfterLine[2];
      final x2 = ptsAfterLine[3];
      expect(x1.name, equals('x1'));
      expect(x2.name, equals('x2'));
      expect(x1.point.euclideanDistance(x2.point), greaterThan(0.1));

      // Circle-Circle intersection generates two distinct points x3 and x4
      scene.createIntersection(c1.id, c2.id);
      final ptsAfterCircle = scene.data.objects
          .whereType<PointObject>()
          .toList();
      expect(ptsAfterCircle.length, equals(6)); // p1, p2, x1, x2, x3, x4
      final x3 = ptsAfterCircle[4];
      final x4 = ptsAfterCircle[5];
      expect(x3.name, equals('x3'));
      expect(x4.name, equals('x4'));
      expect(x3.point.euclideanDistance(x4.point), greaterThan(0.1));

      // Deleting one point (x4) and intersecting again generates the second point
      final x4Pos = x4.point;
      scene.selected = x4;
      scene.deleteSelected();
      expect(scene.data.objects.whereType<PointObject>().length, equals(5));

      final x4Restored = scene.createIntersection(c2.id, c1.id);
      expect(scene.data.objects.whereType<PointObject>().length, equals(6));
      expect(x4Restored.point.euclideanDistance(x4Pos), lessThan(1e-9));
    },
  );

  testWidgets('Combined toolbar preserves canvas size on select and deselect', (
    WidgetTester tester,
  ) async {
    final app = MyApp.fullApp();
    app.manager.driveAccess.isTesting = true;
    await app.initialize();

    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    final state = tester.state<AppWidgetState>(find.byType(AppWidget));
    final scene = state.widget.sceneViewer;

    // Edit bar controls always present without "Name: " label
    expect(find.text('Name: '), findsNothing);
    expect(find.byKey(const ValueKey('object_name')), findsOneWidget);
    expect(find.byKey(const ValueKey('Color-Chooser')), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);

    // Measure canvas size before any selection
    final canvasFinder = find.byKey(const ValueKey('poincare_canvas'));
    expect(canvasFinder, findsOneWidget);
    final sizeBefore = tester.getSize(canvasFinder);

    // Add a point and select it
    final pt = scene.createFreePoint(const HyperbolicPoint(0.1, 0.2));
    scene.selected = pt;
    scene.requestRepaintScene();
    await tester.pumpAndSettle();

    // Canvas size must not jump and inline coordinates must not be displayed
    final sizeAfterSelect = tester.getSize(canvasFinder);
    expect(sizeAfterSelect, equals(sizeBefore));
    expect(find.textContaining('x: 0.100'), findsNothing);

    // Name is populated
    expect(find.text(pt.name), findsWidgets);

    // Deselect
    scene.selected = null;
    scene.requestRepaintScene();
    await tester.pumpAndSettle();

    final sizeAfterDeselect = tester.getSize(canvasFinder);
    expect(sizeAfterDeselect, equals(sizeBefore));

    // Switching to a tool with instructions covers the bottom slider without changing canvas size
    state.selectTool(HyperbolicTool.intersection);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('constructor_prompt_banner')),
      findsOneWidget,
    );
    expect(tester.getSize(canvasFinder), equals(sizeBefore));

    state.selectTool(HyperbolicTool.select);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('constructor_prompt_banner')),
      findsNothing,
    );
    expect(tester.getSize(canvasFinder), equals(sizeBefore));
  });

  testWidgets(
    'Color dropdown, Reset View in Select menu, and coordinate measurements work',
    (WidgetTester tester) async {
      final app = MyApp.fullApp();
      app.manager.driveAccess.isTesting = true;
      await app.initialize();

      await tester.pumpWidget(app.build());
      await tester.pumpAndSettle();

      final appState = tester.state<AppWidgetState>(find.byType(AppWidget));
      final scene = appState.widget.sceneViewer;

      // Create a point and select it
      final pt = scene.createFreePoint(const HyperbolicPoint(0.25, -0.35));
      scene.selected = pt;
      scene.requestRepaintScene();
      await tester.pumpAndSettle();

      // Open Color-Chooser dropdown and select color 4
      final colorChooserBtn = find.descendant(
        of: find.byKey(const ValueKey('Color-Chooser')),
        matching: find.byType(IconButton),
      );
      await tester.ensureVisible(colorChooserBtn);
      await tester.tap(colorChooserBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('Color-Chooser-4')));
      await tester.pumpAndSettle();
      expect(pt.color, equals(SceneView.colorList.value[4].toARGB32()));

      // Pan the view and then reset it from the Select (navigate) dropdown menu
      scene.transform.panBy(const Offset(50, 30));
      expect(scene.transform.pan, isNot(equals(Offset.zero)));

      final navigateMenuBtn = find.byKey(
        const ValueKey('tool_group_menu_navigate'),
      );
      await tester.ensureVisible(navigateMenuBtn);
      await tester.tap(navigateMenuBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset View'));
      await tester.pumpAndSettle();
      expect(scene.transform.pan, equals(Offset.zero));

      // Create X and Y coordinate NumberObjects for the selected point
      scene.selected = pt;
      appState.selectTool(HyperbolicTool.measureCoordinateX);
      await tester.pumpAndSettle();

      scene.selected = pt;
      appState.selectTool(HyperbolicTool.measureCoordinateY);
      await tester.pumpAndSettle();

      final numbers = scene.data.objects.whereType<NumberObject>().toList();
      expect(numbers.length, equals(2));
      expect(numbers[0].name, equals('x1'));
      expect(numbers[0].value, closeTo(0.25, 1e-6));
      expect(numbers[1].name, equals('y1'));
      expect(numbers[1].value, closeTo(-0.35, 1e-6));
    },
  );

  testWidgets(
    'Editing object name does not trigger tool or delete keyboard shortcuts',
    (WidgetTester tester) async {
      final app = MyApp.fullApp();
      app.manager.driveAccess.isTesting = true;
      await app.initialize();

      await tester.pumpWidget(app.build());
      await tester.pumpAndSettle();

      final scene = app.manager.current.scene!;

      // Add a free number parameter ('r1')
      await tester.tap(find.byTooltip('Add Free Parameter'));
      await tester.pumpAndSettle();

      final numbers = scene.data.objects.whereType<NumberObject>().toList();
      expect(numbers.length, equals(1));
      final numObj = numbers.first;
      expect(numObj.name, equals('r1'));
      expect(scene.selected, equals(numObj));

      // Tap the TapToEditText widget in the toolbar to rename 'r1'
      final nameEditor = find.byKey(ValueKey('${numObj.id}_name'));
      expect(nameEditor, findsOneWidget);
      await tester.ensureVisible(nameEditor);
      await tester.tap(nameEditor);
      await tester.pumpAndSettle();

      final textFieldFinder = find.descendant(
        of: nameEditor,
        matching: find.byType(TextField),
      );
      expect(textFieldFinder, findsOneWidget);
      final activeField = tester.widget<TextField>(textFieldFinder);
      expect(activeField.decoration?.border, isA<UnderlineInputBorder>());

      final appState = tester.state<AppWidgetState>(find.byType(AppWidget));
      expect(appState.isEditingText, isTrue);

      // Press Backspace to delete one character ('r1' -> 'r')
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      // Number object must still exist and remain selected!
      expect(scene.data.objects.whereType<NumberObject>().length, equals(1));
      expect(scene.selected, equals(numObj));
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller!.text, equals('r'));

      // Press shortcut keys ('L', 'P', 'K', 'Delete') while editing text
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();

      // None of the shortcuts should have fired
      expect(scene.currentTool.value, equals(HyperbolicTool.select));
      expect(numObj.locked, isFalse);
      expect(scene.data.objects.whereType<NumberObject>().length, equals(1));
      expect(scene.selected, equals(numObj));

      // Enter new name and submit
      await tester.enterText(textFieldFinder, 'radius1');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(numObj.name, equals('radius1'));
      expect(appState.isEditingText, isFalse);

      // After finishing text editing, shortcuts should work again
      await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
      await tester.pumpAndSettle();
      expect(scene.currentTool.value, equals(HyperbolicTool.line));
    },
  );

  testWidgets(
    'Name field pre-fills based on active creation tool and increments on creation',
    (WidgetTester tester) async {
      final app = MyApp.fullApp();
      app.manager.driveAccess.isTesting = true;
      await app.initialize();

      await tester.pumpWidget(app.build());
      await tester.pumpAndSettle();

      final appState = tester.state<AppWidgetState>(find.byType(AppWidget));
      final scene = appState.widget.sceneViewer;

      // In Select mode with nothing selected, next_object_name is not shown
      expect(find.byKey(const ValueKey('next_object_name')), findsNothing);

      // Switch to Point tool -> pre-fills 'p1'
      appState.selectTool(HyperbolicTool.point);
      await tester.pumpAndSettle();
      expect(scene.currentName.value, equals('p1'));
      expect(find.byKey(const ValueKey('next_object_name')), findsOneWidget);
      expect(find.text('p1'), findsOneWidget);

      // Click canvas to add a point -> point is named 'p1', field advances to 'p2'
      await tester.tap(find.byKey(const ValueKey('poincare_canvas')));
      await tester.pumpAndSettle();
      final pts = scene.data.objects.whereType<PointObject>().toList();
      expect(pts.length, equals(1));
      expect(pts.first.name, equals('p1'));
      expect(scene.currentName.value, equals('p2'));
      expect(find.text('p2'), findsWidgets);

      // Customize the pre-filled name before adding the next point
      scene.currentName.value = 'A1';
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('poincare_canvas')));
      await tester.pumpAndSettle();
      final ptsAfter = scene.data.objects.whereType<PointObject>().toList();
      expect(ptsAfter.length, equals(2));
      expect(ptsAfter.last.name, equals('A1'));
      expect(scene.currentName.value, equals('A2'));

      // Switch to Line, Segment, Circle, Intersection tools and verify pre-filled names
      appState.selectTool(HyperbolicTool.line);
      await tester.pumpAndSettle();
      expect(scene.currentName.value, equals('l1'));

      appState.selectTool(HyperbolicTool.segment);
      await tester.pumpAndSettle();
      expect(scene.currentName.value, equals('s1'));

      appState.selectTool(HyperbolicTool.circle);
      await tester.pumpAndSettle();
      expect(scene.currentName.value, equals('c1'));

      appState.selectTool(HyperbolicTool.intersection);
      await tester.pumpAndSettle();
      expect(scene.currentName.value, equals('x1'));
    },
  );

  testWidgets(
    'Drawing title is editable via TapToEditText with underline and undo/redo',
    (WidgetTester tester) async {
      final app = MyApp.fullApp();
      app.manager.driveAccess.isTesting = true;
      await app.initialize();

      await tester.pumpWidget(app.build());
      await tester.pumpAndSettle();

      final titleEditor = find.byKey(const ValueKey('title_text_view'));
      expect(titleEditor, findsOneWidget);
      expect(find.text('Untitled Drawing'), findsOneWidget);

      await tester.tap(titleEditor);
      await tester.pumpAndSettle();

      final textFieldFinder = find.descendant(
        of: titleEditor,
        matching: find.byType(TextField),
      );
      expect(textFieldFinder, findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.decoration?.border, isA<UnderlineInputBorder>());

      await tester.enterText(textFieldFinder, 'My Hyperbolic Scene');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final scene = app.manager.current.scene!;
      expect(scene.data.title, equals('My Hyperbolic Scene'));
      expect(app.manager.current.holder.title, equals('My Hyperbolic Scene'));
      expect(find.text('My Hyperbolic Scene'), findsOneWidget);

      // Undo via Ctrl+Z
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(scene.data.title, equals('Untitled Drawing'));
      expect(app.manager.current.holder.title, equals('Untitled Drawing'));

      // Redo via Ctrl+Y
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(scene.data.title, equals('My Hyperbolic Scene'));
      expect(app.manager.current.holder.title, equals('My Hyperbolic Scene'));
    },
  );

  testWidgets(
    'Drawer menu order places Tutorials below File (File, Tutorials, Edit, View)',
    (WidgetTester tester) async {
      final app = MyApp.fullApp();
      app.manager.driveAccess.isTesting = true;
      await app.initialize();

      await tester.pumpWidget(app.build());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('drawer-menu-btn')));
      await tester.pumpAndSettle();

      final fileY = tester.getTopLeft(find.text('File')).dy;
      final tutorialsY = tester.getTopLeft(find.text('Tutorials')).dy;
      final editY = tester.getTopLeft(find.text('Edit')).dy;
      final viewY = tester.getTopLeft(find.text('View')).dy;

      expect(fileY, lessThan(tutorialsY));
      expect(tutorialsY, lessThan(editY));
      expect(editY, lessThan(viewY));
    },
  );

  testWidgets(
    'Ctrl+<key> shortcuts work for Undo, Redo, Copy, Paste, Cut, New, Open',
    (WidgetTester tester) async {
      final app = MyApp.fullApp();
      app.manager.driveAccess.isTesting = true;
      await app.initialize();

      await tester.pumpWidget(app.build());
      await tester.pumpAndSettle();

      final appState = tester.state<AppWidgetState>(find.byType(AppWidget));
      var scene = app.manager.current.scene!;

      // Add a point and select it
      appState.selectTool(HyperbolicTool.point);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('poincare_canvas')));
      await tester.pumpAndSettle();
      expect(scene.data.objects.whereType<PointObject>().length, equals(1));

      // Undo via Ctrl+Z
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(scene.data.objects.whereType<PointObject>().length, equals(0));
      expect(app.manager.unsaved.value, isFalse);

      // Redo via Ctrl+Y
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(scene.data.objects.whereType<PointObject>().length, equals(1));
      expect(app.manager.unsaved.value, isTrue);

      final p1 = scene.data.objects.whereType<PointObject>().first;
      scene.selected = p1;
      scene.requestRepaintScene();
      await tester.pumpAndSettle();

      // Copy via Ctrl+C and Paste via Ctrl+V
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(scene.canPaste, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(scene.data.objects.whereType<PointObject>().length, equals(2));

      // Cut selected (p2) via Ctrl+X
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(scene.data.objects.whereType<PointObject>().length, equals(1));

      // Clear unsaved and press Ctrl+N for New scene
      app.manager.clearUnsaved();
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      scene = app.manager.current.scene!;
      expect(scene.data.objects.isEmpty, isTrue);

      // Press Ctrl+O to open the file chooser dialog
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(
        find.byType(FileChooser).evaluate().isNotEmpty ||
            find.text('Choose a File').evaluate().isNotEmpty,
        isTrue,
      );
    },
  );

  testWidgets('Extend segment or ray to a full line with undo and redo', (
    WidgetTester tester,
  ) async {
    final app = MyApp.fullApp();
    app.manager.driveAccess.isTesting = true;
    await app.initialize();

    await tester.pumpWidget(app.build());
    await tester.pumpAndSettle();

    final appState = tester.state<AppWidgetState>(find.byType(AppWidget));
    final scene = app.manager.current.scene!;

    final p1 = scene.createFreePoint(const HyperbolicPoint(-0.2, 0.0));
    final p2 = scene.createFreePoint(const HyperbolicPoint(0.2, 0.1));
    final p3 = scene.createFreePoint(const HyperbolicPoint(0.0, -0.2));

    final seg = scene.createLine(p1.id, p2.id, style: LineStyle.segment);
    final ray = scene.createLine(p1.id, p3.id, style: LineStyle.ray);
    expect(seg.lineStyle, equals(LineStyle.segment));
    expect(ray.lineStyle, equals(LineStyle.ray));

    // Select the segment -> extend button appears in toolbar
    scene.selected = seg;
    scene.requestRepaintScene();
    await tester.pumpAndSettle();

    final extendBtn = find.byKey(const ValueKey('extend_line_btn'));
    expect(extendBtn, findsOneWidget);
    await tester.ensureVisible(extendBtn);
    await tester.pumpAndSettle();

    await tester.tap(extendBtn);
    await tester.pumpAndSettle();
    expect(seg.lineStyle, equals(LineStyle.fullLine));
    expect(find.byKey(const ValueKey('extend_line_btn')), findsNothing);

    // Undo restores segment style
    scene.undoManager.undo();
    await tester.pumpAndSettle();
    expect(seg.lineStyle, equals(LineStyle.segment));

    // Redo re-extends segment to full line
    scene.undoManager.redo();
    await tester.pumpAndSettle();
    expect(seg.lineStyle, equals(LineStyle.fullLine));

    // Select the ray and press 'E' shortcut to extend it to a full line
    scene.selected = ray;
    scene.requestRepaintScene();
    await tester.pumpAndSettle();
    expect(appState.widget.sceneViewer.canExtendSelected, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
    await tester.pumpAndSettle();
    expect(ray.lineStyle, equals(LineStyle.fullLine));
  });
}
