import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../color.dart';
import '../constraints/constraints.dart';
import '../edit.dart';
import '../file_manager.dart';
import '../l10n/l10n_extension.dart';
import '../name.dart';
import '../objects/objects.dart';
import '../settings.dart';
import '../transform.dart';
import 'scene_data.dart';

/// Available interactive tools in the hyperbolic drawing workspace.
enum HyperbolicTool {
  select('Select', Icons.near_me, 'Esc'),
  moveDisk('Möbius Move', Icons.open_with, 'H'),
  panZoom('Pan & Zoom', Icons.zoom_in),
  point('Point', Icons.lens, 'P'),
  midpoint('Midpoint', Icons.adjust, 'M'),
  intersection('Intersection', Icons.close, 'I'),
  line('Line', Icons.linear_scale, 'L'),
  segment('Segment', Icons.horizontal_rule, 'S'),
  ray('Ray', Icons.trending_flat, 'R'),
  extendLine('Extend to Line', Icons.open_in_full, 'E'),
  perpendicular('Perpendicular', Icons.square_foot),
  perpendicularBisector('Perp. Bisector', Icons.vertical_align_center),
  angleBisector('Angle Bisector', Icons.call_split),
  circle('Circle', Icons.radio_button_unchecked, 'C'),
  circleRadius('Circle (Radius)', Icons.circle_outlined),
  compass('Compass', Icons.donut_large),
  equilateralTriangle('Equilateral △', Icons.change_history),
  measureDistance('Distance', Icons.straighten, 'D'),
  measureAngle('Angle', Icons.architecture, 'A'),
  measureCoordinateX('X Coordinate', Icons.swap_horiz),
  measureCoordinateY('Y Coordinate', Icons.swap_vert);

  final String label;
  final IconData icon;
  final String? shortcutKey;

  const HyperbolicTool(this.label, this.icon, [this.shortcutKey]);

  String get tooltip => shortcutKey != null ? '$label ($shortcutKey)' : label;

  /// Default initial name prefix when creating a new object with this tool,
  /// or `null` for navigation/selection tools that do not create objects.
  String? get defaultNamePrefix {
    switch (this) {
      case HyperbolicTool.select:
      case HyperbolicTool.moveDisk:
      case HyperbolicTool.panZoom:
      case HyperbolicTool.extendLine:
        return null;
      case HyperbolicTool.point:
      case HyperbolicTool.equilateralTriangle:
        return 'p1';
      case HyperbolicTool.midpoint:
        return 'm1';
      case HyperbolicTool.intersection:
      case HyperbolicTool.measureCoordinateX:
        return 'x1';
      case HyperbolicTool.measureCoordinateY:
        return 'y1';
      case HyperbolicTool.line:
      case HyperbolicTool.perpendicular:
      case HyperbolicTool.perpendicularBisector:
        return 'l1';
      case HyperbolicTool.segment:
        return 's1';
      case HyperbolicTool.ray:
      case HyperbolicTool.angleBisector:
        return 'r1';
      case HyperbolicTool.circle:
      case HyperbolicTool.circleRadius:
      case HyperbolicTool.compass:
        return 'c1';
      case HyperbolicTool.measureDistance:
        return 'd1';
      case HyperbolicTool.measureAngle:
        return 'α 1';
    }
  }
}

/// Functional grouping of constructor tools for toolbar organization.
enum ToolGroup {
  navigate('Navigate', Icons.open_with, [
    HyperbolicTool.select,
    HyperbolicTool.moveDisk,
    HyperbolicTool.panZoom,
  ]),
  points('Points', Icons.lens, [
    HyperbolicTool.point,
    HyperbolicTool.midpoint,
    HyperbolicTool.intersection,
  ]),
  lines('Lines', Icons.linear_scale, [
    HyperbolicTool.line,
    HyperbolicTool.segment,
    HyperbolicTool.ray,
    HyperbolicTool.extendLine,
  ]),
  circles('Circles', Icons.radio_button_unchecked, [
    HyperbolicTool.circle,
    HyperbolicTool.circleRadius,
  ]),
  measure('Measure', Icons.straighten, [
    HyperbolicTool.measureDistance,
    HyperbolicTool.measureAngle,
    HyperbolicTool.measureCoordinateX,
    HyperbolicTool.measureCoordinateY,
  ]),
  construct('Construct', Icons.change_history, [
    HyperbolicTool.equilateralTriangle,
    HyperbolicTool.perpendicularBisector,
    HyperbolicTool.angleBisector,
    HyperbolicTool.perpendicular,
    HyperbolicTool.compass,
  ]);

  static const List<ToolGroup> canvasGroups = [
    navigate,
    points,
    lines,
    circles,
    construct,
  ];

  final String label;
  final IconData icon;
  final List<HyperbolicTool> tools;

  const ToolGroup(this.label, this.icon, this.tools);

  static ToolGroup forTool(HyperbolicTool tool) {
    for (final g in values) {
      if (g.tools.contains(tool)) return g;
    }
    return navigate;
  }
}

extension HyperbolicToolLocalization on HyperbolicTool {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case HyperbolicTool.select:
        return l10n.toolSelect;
      case HyperbolicTool.moveDisk:
        return l10n.toolMoveDisk;
      case HyperbolicTool.panZoom:
        return l10n.toolPanZoom;
      case HyperbolicTool.point:
        return l10n.toolPoint;
      case HyperbolicTool.midpoint:
        return l10n.toolMidpoint;
      case HyperbolicTool.intersection:
        return l10n.toolIntersection;
      case HyperbolicTool.line:
        return l10n.toolLine;
      case HyperbolicTool.segment:
        return l10n.toolSegment;
      case HyperbolicTool.ray:
        return l10n.toolRay;
      case HyperbolicTool.extendLine:
        return 'Extend to Line';
      case HyperbolicTool.perpendicular:
        return l10n.toolPerpendicular;
      case HyperbolicTool.perpendicularBisector:
        return l10n.toolPerpendicularBisector;
      case HyperbolicTool.angleBisector:
        return l10n.toolAngleBisector;
      case HyperbolicTool.circle:
        return l10n.toolCircle;
      case HyperbolicTool.circleRadius:
        return l10n.toolCircleRadius;
      case HyperbolicTool.compass:
        return l10n.toolCompass;
      case HyperbolicTool.equilateralTriangle:
        return l10n.toolEquilateralTriangle;
      case HyperbolicTool.measureDistance:
        return l10n.toolMeasureDistance;
      case HyperbolicTool.measureAngle:
        return l10n.toolMeasureAngle;
      case HyperbolicTool.measureCoordinateX:
        return l10n.toolMeasureCoordX;
      case HyperbolicTool.measureCoordinateY:
        return l10n.toolMeasureCoordY;
    }
  }
}

extension ToolGroupLocalization on ToolGroup {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case ToolGroup.navigate:
        return l10n.toolGroupNavigate;
      case ToolGroup.points:
        return l10n.toolGroupPoints;
      case ToolGroup.lines:
        return l10n.toolGroupLines;
      case ToolGroup.circles:
        return l10n.toolGroupCircles;
      case ToolGroup.measure:
        return l10n.toolGroupMeasure;
      case ToolGroup.construct:
        return l10n.toolGroupConstruct;
    }
  }
}

/// Interactive controller managing canvas tools, gestures, selections,
/// undo/redo history, and coordinate transformations.
class SceneView {
  final FileManager fileManager;
  final Settings settings;
  SceneData data;
  MyUndoManager undoManager = MyUndoManager();

  ValueNotifier<HyperbolicTool> currentTool = ValueNotifier<HyperbolicTool>(
    HyperbolicTool.select,
  );
  ValueNotifier<String> currentName = ValueNotifier<String>('');
  ValueNotifier<int> repaintCounter = ValueNotifier<int>(0);
  ValueNotifier<bool> showAxes = ValueNotifier<bool>(true);

  static final List<Color> colorListDark = [
    Colors.black,
    Colors.purple.shade900,
    Colors.blue.shade900,
    Colors.teal.shade900,
    Colors.cyan.shade900,
    Colors.green.shade900,
    Colors.orange.shade900,
    Colors.red.shade900,
    Colors.brown.shade900,
  ];

  static final List<Color> colorListLight = [
    Colors.white,
    Colors.purple.shade300,
    Colors.blue.shade300,
    Colors.teal.shade300,
    Colors.cyan.shade300,
    Colors.green.shade300,
    Colors.orange.shade300,
    Colors.red.shade300,
    Colors.brown.shade300,
  ];

  static SavableColorArray colorList = SavableColorArray(
    'color_list',
    'Object Colors',
    colorListLight,
    (scheme) => (scheme.brightness == Brightness.light)
        ? List.from(colorListDark)
        : List.from(colorListLight),
  );

  ValueNotifier<int> currentColorIndex = ValueNotifier<int>(2);
  Color get currentColor =>
      colorList.value[currentColorIndex.value % colorList.value.length];

  SceneObject? _selected;
  SceneObject? get selected => _selected;
  set selected(SceneObject? value) {
    if (_selected != value) {
      _selected = value;
      undoManager.rebuildMenu();
    }
  }

  SceneObject? hoveredObject;
  Map<String, dynamic>? _copiedObjectJson;
  List<Map<String, dynamic>> _copiedConstraintJsons = [];
  bool get canPaste => _copiedObjectJson != null;

  // Creation workflow state
  HyperbolicPoint? creationFirstPoint;
  String? creationFirstObjId;
  String? creationSecondObjId;
  HyperbolicPoint? hoverPoint;

  // Gesture state
  Offset? _lastPointerPos;
  HyperbolicPoint? _dragStartDiskPos;
  HyperbolicPoint? _dragStartViewPos;
  MobiusTransform? _dragStartMobius;
  SceneObject? _draggingObject;
  bool _isDraggingDisk = false;

  final NameGuess nameGuess = NameGuess();
  HyperbolicTool? _nameTool;
  static int _idCounter = 0;

  static String nextObjectId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${++_idCounter}';

  SceneView(this.fileManager, this.settings, this.data) {
    undoManager.onUnsavedChanged = (isUnsaved) {
      fileManager.unsaved.value = isUnsaved;
    };
    ensureToolListener();
  }

  void ensureToolListener() {
    currentTool.removeListener(updateDefaultNameForCurrentTool);
    currentTool.addListener(updateDefaultNameForCurrentTool);
    if (_nameTool != currentTool.value ||
        (currentTool.value.defaultNamePrefix != null &&
            currentName.value.trim().isEmpty)) {
      updateDefaultNameForCurrentTool();
    }
  }

  void updateDefaultNameForCurrentTool() {
    _nameTool = currentTool.value;
    final prefix = currentTool.value.defaultNamePrefix;
    if (prefix != null) {
      currentName.value = NameGuess.nextAvailableName(
        prefix,
        data.objects.map((o) => o.name),
      );
    } else if (selected == null) {
      currentName.value = '';
    }
  }

  String _nextNameForCreation(
    String defaultPrefix, {
    required bool isActiveToolTarget,
  }) {
    if (isActiveToolTarget && _nameTool != currentTool.value) {
      updateDefaultNameForCurrentTool();
    }
    final seed = (isActiveToolTarget && currentName.value.trim().isNotEmpty)
        ? currentName.value.trim()
        : defaultPrefix;
    return NameGuess.nextAvailableName(seed, data.objects.map((o) => o.name));
  }

  void _afterCreation(String createdName, {required bool isActiveToolTarget}) {
    _nameTool = currentTool.value;
    if (isActiveToolTarget) {
      currentName.value = NameGuess.nextAvailableName(
        createdName,
        data.objects.map((o) => o.name),
      );
    } else if (currentTool.value.defaultNamePrefix != null) {
      final seed = currentName.value.trim().isNotEmpty
          ? currentName.value.trim()
          : currentTool.value.defaultNamePrefix!;
      currentName.value = NameGuess.nextAvailableName(
        seed,
        data.objects.map((o) => o.name),
      );
    }
  }

  CoordinateTransform get transform => data.transform;

  void requestRepaintScene() {
    if (_selected != null && data.graph.getObject(_selected!.id) == null) {
      _selected = null;
      undoManager.rebuildMenu();
    }
    repaintCounter.value++;
  }

  void cancelActiveCreation() {
    creationFirstPoint = null;
    creationFirstObjId = null;
    creationSecondObjId = null;
    requestRepaintScene();
  }

  void selectObject(SceneObject? obj) {
    selected = obj;
    if (currentTool.value == HyperbolicTool.circleRadius &&
        creationFirstObjId != null &&
        obj is NumberObject) {
      createCircleWithRadius(creationFirstObjId!, obj.id);
      cancelActiveCreation();
    }
    requestRepaintScene();
  }

  /// Dynamic contextual instruction prompt for the active constructor tool.
  String? get currentPrompt {
    switch (currentTool.value) {
      case HyperbolicTool.point:
        return 'Click anywhere inside the Poincaré disk to place a point.';
      case HyperbolicTool.line:
        return creationFirstObjId == null
            ? 'Select first point (or click canvas to place one)'
            : 'Select second point (or click canvas to place one)';
      case HyperbolicTool.segment:
        return creationFirstObjId == null
            ? 'Select first endpoint'
            : 'Select second endpoint';
      case HyperbolicTool.ray:
        return creationFirstObjId == null
            ? 'Select start point'
            : 'Select direction point';
      case HyperbolicTool.extendLine:
        return 'Select a segment or ray to extend to a full line';
      case HyperbolicTool.midpoint:
        return creationFirstObjId == null
            ? 'Select first point or click a segment'
            : 'Select second point';
      case HyperbolicTool.perpendicular:
        return creationFirstObjId == null
            ? 'Select base line'
            : 'Select point on or off the line (or click canvas)';
      case HyperbolicTool.perpendicularBisector:
        return creationFirstObjId == null
            ? 'Select first point or click a segment'
            : 'Select second point';
      case HyperbolicTool.angleBisector:
        if (creationFirstObjId == null) {
          return 'Select first point on ray 1';
        } else if (creationSecondObjId == null) {
          return 'Select angle vertex point';
        } else {
          return 'Select point on ray 2';
        }
      case HyperbolicTool.circle:
        return creationFirstObjId == null
            ? 'Select center point (or click canvas)'
            : 'Select point on circumference (or click canvas)';
      case HyperbolicTool.circleRadius:
        return creationFirstObjId == null
            ? 'Select center point (or click canvas)'
            : 'Select a radius Number object in the panel';
      case HyperbolicTool.compass:
        if (creationFirstObjId == null) {
          return 'Select first point of radius segment';
        } else if (creationSecondObjId == null) {
          return 'Select second point of radius segment';
        } else {
          return 'Select center point for the compass circle';
        }
      case HyperbolicTool.equilateralTriangle:
        return creationFirstObjId == null
            ? 'Select first base vertex point (or click canvas)'
            : 'Select second base vertex point (or click canvas)';
      case HyperbolicTool.intersection:
        return creationFirstObjId == null
            ? 'Select first line or circle'
            : 'Select second line or circle';
      case HyperbolicTool.measureDistance:
        return creationFirstObjId == null
            ? 'Select first point'
            : 'Select second point';
      case HyperbolicTool.measureAngle:
        if (creationFirstObjId == null) {
          return 'Select first point on first leg';
        } else if (creationSecondObjId == null) {
          return 'Select vertex point';
        } else {
          return 'Select point on second leg';
        }
      case HyperbolicTool.measureCoordinateX:
        return 'Select a point to create an x-coordinate number';
      case HyperbolicTool.measureCoordinateY:
        return 'Select a point to create a y-coordinate number';
      default:
        return null;
    }
  }

  String? localizedPrompt(AppLocalizations l10n) {
    switch (currentTool.value) {
      case HyperbolicTool.point:
        return l10n.promptPoint;
      case HyperbolicTool.line:
        return creationFirstObjId == null
            ? l10n.promptLineFirst
            : l10n.promptLineSecond;
      case HyperbolicTool.segment:
        return creationFirstObjId == null
            ? l10n.promptSegmentFirst
            : l10n.promptSegmentSecond;
      case HyperbolicTool.ray:
        return creationFirstObjId == null
            ? l10n.promptRayFirst
            : l10n.promptRaySecond;
      case HyperbolicTool.extendLine:
        return 'Select a segment or ray to extend to a full line';
      case HyperbolicTool.midpoint:
        return creationFirstObjId == null
            ? l10n.promptMidpointFirst
            : l10n.promptMidpointSecond;
      case HyperbolicTool.perpendicular:
        return creationFirstObjId == null
            ? l10n.promptPerpendicularFirst
            : l10n.promptPerpendicularSecond;
      case HyperbolicTool.perpendicularBisector:
        return creationFirstObjId == null
            ? l10n.promptPerpBisectorFirst
            : l10n.promptPerpBisectorSecond;
      case HyperbolicTool.angleBisector:
        if (creationFirstObjId == null) {
          return l10n.promptAngleBisectorFirst;
        } else if (creationSecondObjId == null) {
          return l10n.promptAngleBisectorVertex;
        } else {
          return l10n.promptAngleBisectorSecond;
        }
      case HyperbolicTool.circle:
        return creationFirstObjId == null
            ? l10n.promptCircleCenter
            : l10n.promptCircleCircumference;
      case HyperbolicTool.circleRadius:
        return creationFirstObjId == null
            ? l10n.promptCircleCenter
            : l10n.promptCircleRadiusNumber;
      case HyperbolicTool.compass:
        if (creationFirstObjId == null) {
          return l10n.promptCompassFirst;
        } else if (creationSecondObjId == null) {
          return l10n.promptCompassSecond;
        } else {
          return l10n.promptCompassCenter;
        }
      case HyperbolicTool.equilateralTriangle:
        return creationFirstObjId == null
            ? l10n.promptEquilateralFirst
            : l10n.promptEquilateralSecond;
      case HyperbolicTool.intersection:
        return creationFirstObjId == null
            ? l10n.promptIntersectionFirst
            : l10n.promptIntersectionSecond;
      case HyperbolicTool.measureDistance:
        return creationFirstObjId == null
            ? l10n.promptMeasureDistFirst
            : l10n.promptMeasureDistSecond;
      case HyperbolicTool.measureAngle:
        if (creationFirstObjId == null) {
          return l10n.promptMeasureAngleFirst;
        } else if (creationSecondObjId == null) {
          return l10n.promptMeasureAngleVertex;
        } else {
          return l10n.promptMeasureAngleSecond;
        }
      case HyperbolicTool.measureCoordinateX:
        return l10n.promptMeasureCoordX;
      case HyperbolicTool.measureCoordinateY:
        return l10n.promptMeasureCoordY;
      default:
        return null;
    }
  }

  void onPointerLeave() {
    hoveredObject = null;
    hoverPoint = null;
    requestRepaintScene();
  }

  // --- Gesture Handling ---

  void onPointerDown(PointerDownEvent event) {
    _lastPointerPos = event.localPosition;
    final diskPt = transform.screenToDisk(event.localPosition);
    hoverPoint = diskPt;
    hoveredObject = hitTest(event.localPosition);

    if (event.buttons == kSecondaryMouseButton ||
        currentTool.value == HyperbolicTool.panZoom) {
      // Pan Euclidean view
      return;
    }

    if (currentTool.value == HyperbolicTool.moveDisk) {
      _isDraggingDisk = true;
      _dragStartDiskPos = diskPt;
      _dragStartViewPos = transform.screenToView(event.localPosition);
      _dragStartMobius = transform.mobius;
      return;
    }

    final hitObj = hitTest(event.localPosition);

    switch (currentTool.value) {
      case HyperbolicTool.select:
        selected = hitObj;
        if (hitObj is PointObject && !hitObj.locked) {
          _draggingObject = hitObj;
          _dragStartDiskPos = hitObj.point;
        }
        requestRepaintScene();
        break;

      case HyperbolicTool.point:
        if (diskPt.magnitudeSquared < 1.0) {
          createFreePoint(diskPt);
        }
        break;

      case HyperbolicTool.midpoint:
        _handleMidpointToolClick(hitObj, diskPt);
        break;

      case HyperbolicTool.line:
      case HyperbolicTool.segment:
      case HyperbolicTool.ray:
        _handleLineToolClick(
          hitObj,
          diskPt,
          style: currentTool.value == HyperbolicTool.segment
              ? LineStyle.segment
              : currentTool.value == HyperbolicTool.ray
              ? LineStyle.ray
              : LineStyle.fullLine,
        );
        break;

      case HyperbolicTool.extendLine:
        if (hitObj is LineObject && hitObj.lineStyle != LineStyle.fullLine) {
          extendLine(hitObj);
        }
        break;

      case HyperbolicTool.perpendicular:
        _handlePerpendicularToolClick(hitObj, diskPt);
        break;

      case HyperbolicTool.perpendicularBisector:
        _handlePerpendicularBisectorToolClick(hitObj, diskPt);
        break;

      case HyperbolicTool.angleBisector:
        _handleAngleBisectorToolClick(hitObj, diskPt);
        break;

      case HyperbolicTool.circle:
        _handleCircleToolClick(hitObj, diskPt);
        break;

      case HyperbolicTool.circleRadius:
        _handleCircleRadiusToolClick(hitObj, diskPt);
        break;

      case HyperbolicTool.compass:
        _handleCompassToolClick(hitObj, diskPt);
        break;

      case HyperbolicTool.equilateralTriangle:
        _handleEquilateralTriangleToolClick(hitObj, diskPt);
        break;

      case HyperbolicTool.intersection:
        _handleIntersectionToolClick(hitObj);
        break;

      case HyperbolicTool.measureDistance:
        _handleDistanceMeasurementClick(hitObj, diskPt);
        break;

      case HyperbolicTool.measureAngle:
        _handleAngleMeasurementClick(hitObj, diskPt);
        break;

      case HyperbolicTool.measureCoordinateX:
        _handleCoordinateMeasurementClick(hitObj, diskPt, 'x');
        break;

      case HyperbolicTool.measureCoordinateY:
        _handleCoordinateMeasurementClick(hitObj, diskPt, 'y');
        break;

      default:
        break;
    }
  }

  void onPointerMove(PointerMoveEvent event) {
    final currentPos = event.localPosition;
    final delta = currentPos - (_lastPointerPos ?? currentPos);
    _lastPointerPos = currentPos;

    final diskPt = transform.screenToDisk(currentPos);
    hoverPoint = diskPt;
    hoveredObject = hitTest(currentPos);

    if (event.buttons == kSecondaryMouseButton ||
        (event.buttons == kPrimaryButton &&
            currentTool.value == HyperbolicTool.panZoom)) {
      transform.panBy(delta);
      requestRepaintScene();
      return;
    }

    if (event.buttons == kPrimaryButton) {
      if (_isDraggingDisk &&
          _dragStartViewPos != null &&
          _dragStartMobius != null) {
        // Drag hyperbolic disk smoothly via Mobius translation
        final currentViewPos = transform.screenToView(currentPos);
        if (_dragStartViewPos!.magnitudeSquared < 0.99 &&
            currentViewPos.magnitudeSquared < 0.99) {
          final m1 = MobiusTransform.translationOnly(_dragStartViewPos!);
          final m2 = MobiusTransform.translationOnly(
            HyperbolicPoint(-currentViewPos.x, -currentViewPos.y),
          );
          final mDelta = m2.compose(m1);
          transform.mobius = mDelta.compose(_dragStartMobius!);
          requestRepaintScene();
        }
        return;
      }

      if (_draggingObject is PointObject) {
        final ptObj = _draggingObject as PointObject;
        if (diskPt.magnitudeSquared < 1.0) {
          data.graph.dragPoint(ptObj.id, diskPt);
          requestRepaintScene();
        }
        return;
      }
    }

    requestRepaintScene();
  }

  void onPointerUp(PointerUpEvent event) {
    hoveredObject = hitTest(event.localPosition);

    if (_isDraggingDisk && _dragStartMobius != null) {
      final startM = _dragStartMobius!;
      final endM = transform.mobius;
      if (startM.translation != endM.translation ||
          startM.rotation != endM.rotation) {
        undoManager.add(
          UndoCallback(
            'Möbius Translation',
            undoCallback: () {
              transform.mobius = startM;
              requestRepaintScene();
            },
            redoCallback: () {
              transform.mobius = endM;
              requestRepaintScene();
            },
          ),
        );
        fileManager.maybeChange();
      }
    }

    if (_draggingObject is PointObject && _dragStartDiskPos != null) {
      final ptObj = _draggingObject as PointObject;
      final startPos = _dragStartDiskPos!;
      final endPos = ptObj.point;

      if (startPos != endPos) {
        undoManager.add(
          UndoCallback(
            'Move ${ptObj.name}',
            undoCallback: () {
              data.graph.dragPoint(ptObj.id, startPos);
              requestRepaintScene();
            },
            redoCallback: () {
              data.graph.dragPoint(ptObj.id, endPos);
              requestRepaintScene();
            },
          ),
        );
        fileManager.maybeChange();
      }
    }

    _draggingObject = null;
    _dragStartDiskPos = null;
    _dragStartViewPos = null;
    _dragStartMobius = null;
    _isDraggingDisk = false;
    requestRepaintScene();
  }

  void onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final double dy = event.scrollDelta.dy;
      if (dy != 0) {
        final zoomFactor = math.exp(-dy / 300.0).clamp(0.8, 1.25);
        transform.zoomAt(event.localPosition, zoomFactor);
        requestRepaintScene();
      }
    }
  }

  void onPointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    if (event.scale != 1.0) {
      transform.zoomAt(event.localPosition, event.scale);
    }
    transform.panBy(event.panDelta);
    requestRepaintScene();
  }

  // --- Tool Click Workflows ---

  void _handleLineToolClick(
    SceneObject? hitObj,
    HyperbolicPoint diskPt, {
    required LineStyle style,
  }) {
    if (style == LineStyle.fullLine &&
        creationFirstPoint == null &&
        hitObj is LineObject &&
        hitObj.lineStyle != LineStyle.fullLine) {
      extendLine(hitObj);
      return;
    }

    PointObject pt;
    if (hitObj is PointObject) {
      pt = hitObj;
    } else {
      if (diskPt.magnitudeSquared >= 1.0) return;
      pt = createFreePoint(diskPt);
    }

    if (creationFirstPoint == null) {
      creationFirstPoint = pt.point;
      creationFirstObjId = pt.id;
    } else {
      if (creationFirstObjId != pt.id) {
        createLine(creationFirstObjId!, pt.id, style: style);
      }
      creationFirstPoint = null;
      creationFirstObjId = null;
    }
    requestRepaintScene();
  }

  void _handleCircleToolClick(SceneObject? hitObj, HyperbolicPoint diskPt) {
    PointObject pt;
    if (hitObj is PointObject) {
      pt = hitObj;
    } else {
      if (diskPt.magnitudeSquared >= 1.0) return;
      pt = createFreePoint(diskPt);
    }

    if (creationFirstPoint == null) {
      creationFirstPoint = pt.point;
      creationFirstObjId = pt.id;
    } else {
      if (creationFirstObjId != pt.id) {
        createCircle(creationFirstObjId!, pt.id);
      }
      creationFirstPoint = null;
      creationFirstObjId = null;
    }
    requestRepaintScene();
  }

  void _handleIntersectionToolClick(SceneObject? hitObj) {
    if (hitObj == null || (hitObj is! LineObject && hitObj is! CircleObject)) {
      return;
    }

    if (creationFirstObjId == null) {
      creationFirstObjId = hitObj.id;
    } else {
      if (creationFirstObjId != hitObj.id) {
        createIntersection(creationFirstObjId!, hitObj.id);
      }
      creationFirstObjId = null;
    }
    requestRepaintScene();
  }

  void _handleDistanceMeasurementClick(
    SceneObject? hitObj,
    HyperbolicPoint diskPt,
  ) {
    PointObject pt;
    if (hitObj is PointObject) {
      pt = hitObj;
    } else {
      if (diskPt.magnitudeSquared >= 1.0) return;
      pt = createFreePoint(diskPt);
    }

    if (creationFirstObjId == null) {
      creationFirstObjId = pt.id;
    } else {
      if (creationFirstObjId != pt.id) {
        createDistanceMeasurement(creationFirstObjId!, pt.id);
      }
      creationFirstObjId = null;
    }
    requestRepaintScene();
  }

  void _handleAngleMeasurementClick(
    SceneObject? hitObj,
    HyperbolicPoint diskPt,
  ) {
    PointObject pt;
    if (hitObj is PointObject) {
      pt = hitObj;
    } else {
      if (diskPt.magnitudeSquared >= 1.0) return;
      pt = createFreePoint(diskPt);
    }

    if (creationFirstObjId == null) {
      creationFirstObjId = pt.id;
    } else if (creationSecondObjId == null) {
      creationSecondObjId = pt.id;
    } else {
      createAngleMeasurement(creationFirstObjId!, creationSecondObjId!, pt.id);
      cancelActiveCreation();
    }
    requestRepaintScene();
  }

  void _handleCoordinateMeasurementClick(
    SceneObject? hitObj,
    HyperbolicPoint diskPt,
    String coordinate,
  ) {
    PointObject pt;
    if (hitObj is PointObject) {
      pt = hitObj;
    } else {
      if (diskPt.magnitudeSquared >= 1.0) return;
      pt = createFreePoint(diskPt);
    }
    createCoordinateMeasurement(pt.id, coordinate);
    cancelActiveCreation();
  }

  void _handleMidpointToolClick(SceneObject? hitObj, HyperbolicPoint diskPt) {
    if (hitObj is LineObject && hitObj.lineStyle == LineStyle.segment) {
      final cid = hitObj.constraintId;
      if (cid != null) {
        final c = data.graph.constraints
            .whereType<LineThroughPointsConstraint>()
            .cast<LineThroughPointsConstraint?>()
            .firstWhere((cn) => cn?.lineId == hitObj.id, orElse: () => null);
        if (c != null) {
          createMidpoint(c.p1Id, c.p2Id);
          cancelActiveCreation();
          return;
        }
      }
    }

    PointObject pt;
    if (hitObj is PointObject) {
      pt = hitObj;
    } else {
      if (diskPt.magnitudeSquared >= 1.0) return;
      pt = createFreePoint(diskPt);
    }

    if (creationFirstObjId == null) {
      creationFirstObjId = pt.id;
    } else {
      if (creationFirstObjId != pt.id) {
        createMidpoint(creationFirstObjId!, pt.id);
      }
      cancelActiveCreation();
    }
    requestRepaintScene();
  }

  void _handlePerpendicularToolClick(
    SceneObject? hitObj,
    HyperbolicPoint diskPt,
  ) {
    if (creationFirstObjId == null) {
      if (hitObj is LineObject) {
        creationFirstObjId = hitObj.id;
      }
    } else {
      PointObject pt;
      if (hitObj is PointObject) {
        pt = hitObj;
      } else {
        if (diskPt.magnitudeSquared >= 1.0) return;
        pt = createFreePoint(diskPt);
      }
      createPerpendicularLine(creationFirstObjId!, pt.id);
      cancelActiveCreation();
    }
    requestRepaintScene();
  }

  void _handlePerpendicularBisectorToolClick(
    SceneObject? hitObj,
    HyperbolicPoint diskPt,
  ) {
    if (hitObj is LineObject && hitObj.lineStyle == LineStyle.segment) {
      final cid = hitObj.constraintId;
      if (cid != null) {
        final c = data.graph.constraints
            .whereType<LineThroughPointsConstraint>()
            .cast<LineThroughPointsConstraint?>()
            .firstWhere((cn) => cn?.lineId == hitObj.id, orElse: () => null);
        if (c != null) {
          createPerpendicularBisector(c.p1Id, c.p2Id);
          cancelActiveCreation();
          return;
        }
      }
    }

    PointObject pt;
    if (hitObj is PointObject) {
      pt = hitObj;
    } else {
      if (diskPt.magnitudeSquared >= 1.0) return;
      pt = createFreePoint(diskPt);
    }

    if (creationFirstObjId == null) {
      creationFirstObjId = pt.id;
    } else {
      if (creationFirstObjId != pt.id) {
        createPerpendicularBisector(creationFirstObjId!, pt.id);
      }
      cancelActiveCreation();
    }
    requestRepaintScene();
  }

  void _handleAngleBisectorToolClick(
    SceneObject? hitObj,
    HyperbolicPoint diskPt,
  ) {
    PointObject pt;
    if (hitObj is PointObject) {
      pt = hitObj;
    } else {
      if (diskPt.magnitudeSquared >= 1.0) return;
      pt = createFreePoint(diskPt);
    }

    if (creationFirstObjId == null) {
      creationFirstObjId = pt.id;
    } else if (creationSecondObjId == null) {
      creationSecondObjId = pt.id;
    } else {
      createAngleBisector(creationFirstObjId!, creationSecondObjId!, pt.id);
      cancelActiveCreation();
    }
    requestRepaintScene();
  }

  void _handleCircleRadiusToolClick(
    SceneObject? hitObj,
    HyperbolicPoint diskPt,
  ) {
    if (creationFirstObjId == null) {
      PointObject pt;
      if (hitObj is PointObject) {
        pt = hitObj;
      } else {
        if (diskPt.magnitudeSquared >= 1.0) return;
        pt = createFreePoint(diskPt);
      }
      creationFirstObjId = pt.id;
    } else if (hitObj is NumberObject) {
      createCircleWithRadius(creationFirstObjId!, hitObj.id);
      cancelActiveCreation();
    }
    requestRepaintScene();
  }

  void _handleCompassToolClick(SceneObject? hitObj, HyperbolicPoint diskPt) {
    PointObject pt;
    if (hitObj is PointObject) {
      pt = hitObj;
    } else {
      if (diskPt.magnitudeSquared >= 1.0) return;
      pt = createFreePoint(diskPt);
    }

    if (creationFirstObjId == null) {
      creationFirstObjId = pt.id;
    } else if (creationSecondObjId == null) {
      creationSecondObjId = pt.id;
    } else {
      createCompassCircle(pt.id, creationFirstObjId!, creationSecondObjId!);
      cancelActiveCreation();
    }
    requestRepaintScene();
  }

  void _handleEquilateralTriangleToolClick(
    SceneObject? hitObj,
    HyperbolicPoint diskPt,
  ) {
    if (hitObj is LineObject && hitObj.lineStyle == LineStyle.segment) {
      final cid = hitObj.constraintId;
      if (cid != null) {
        final c = data.graph.constraints
            .whereType<LineThroughPointsConstraint>()
            .cast<LineThroughPointsConstraint?>()
            .firstWhere((cn) => cn?.lineId == hitObj.id, orElse: () => null);
        if (c != null) {
          createEquilateralTriangle(c.p1Id, c.p2Id);
          cancelActiveCreation();
          return;
        }
      }
    }

    PointObject pt;
    if (hitObj is PointObject) {
      pt = hitObj;
    } else {
      if (diskPt.magnitudeSquared >= 1.0) return;
      pt = createFreePoint(diskPt);
    }

    if (creationFirstObjId == null) {
      creationFirstObjId = pt.id;
    } else {
      if (creationFirstObjId != pt.id) {
        createEquilateralTriangle(creationFirstObjId!, pt.id);
      }
      cancelActiveCreation();
    }
    requestRepaintScene();
  }

  // --- Object Creation Actions ---

  PointObject createFreePoint(HyperbolicPoint pos) {
    final id = nextObjectId('pt');
    final isTarget = currentTool.value == HyperbolicTool.point;
    final name = _nextNameForCreation('p1', isActiveToolTarget: isTarget);
    final pt = PointObject(
      id: id,
      name: name,
      point: pos,
      color: currentColor.toARGB32(),
    );
    final c = FreePointConstraint(id: 'c_$id', pointId: id);

    data.graph.addObject(pt);
    data.graph.addConstraint(c);
    data.graph.evaluateAll();
    _afterCreation(name, isActiveToolTarget: isTarget);

    undoManager.add(
      UndoCallback(
        'Add Point $name',
        undoCallback: () {
          data.graph.removeObject(id);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.addObject(pt);
          data.graph.addConstraint(c);
          data.graph.evaluateAll();
          _afterCreation(name, isActiveToolTarget: isTarget);
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    requestRepaintScene();
    return pt;
  }

  LineObject createLine(
    String p1Id,
    String p2Id, {
    LineStyle style = LineStyle.fullLine,
  }) {
    final id = nextObjectId('line');
    final expectedTool = style == LineStyle.segment
        ? HyperbolicTool.segment
        : style == LineStyle.ray
        ? HyperbolicTool.ray
        : HyperbolicTool.line;
    final isTarget = currentTool.value == expectedTool;
    final prefix = style == LineStyle.segment
        ? 's1'
        : style == LineStyle.ray
        ? 'r1'
        : 'l1';
    final name = _nextNameForCreation(prefix, isActiveToolTarget: isTarget);
    final line = LineObject(
      id: id,
      name: name,
      lineStyle: style,
      color: currentColor.toARGB32(),
    );
    final c = LineThroughPointsConstraint(
      id: 'c_$id',
      p1Id: p1Id,
      p2Id: p2Id,
      lineId: id,
    );

    data.graph.addObject(line);
    data.graph.addConstraint(c);
    data.graph.evaluateAll();
    _afterCreation(name, isActiveToolTarget: isTarget);

    undoManager.add(
      UndoCallback(
        'Add Line $name',
        undoCallback: () {
          data.graph.removeObject(id);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.addObject(line);
          data.graph.addConstraint(c);
          data.graph.evaluateAll();
          _afterCreation(name, isActiveToolTarget: isTarget);
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    requestRepaintScene();
    return line;
  }

  CircleObject createCircle(String centerId, String pointOnCircleId) {
    final id = nextObjectId('circ');
    final isTarget = currentTool.value == HyperbolicTool.circle;
    final name = _nextNameForCreation('c1', isActiveToolTarget: isTarget);
    final circle = CircleObject(
      id: id,
      name: name,
      color: currentColor.toARGB32(),
    );
    final c = CircleCenterPointConstraint(
      id: 'c_$id',
      centerId: centerId,
      pointOnCircleId: pointOnCircleId,
      circleId: id,
    );

    data.graph.addObject(circle);
    data.graph.addConstraint(c);
    data.graph.evaluateAll();
    _afterCreation(name, isActiveToolTarget: isTarget);

    undoManager.add(
      UndoCallback(
        'Add Circle $name',
        undoCallback: () {
          data.graph.removeObject(id);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.addObject(circle);
          data.graph.addConstraint(c);
          data.graph.evaluateAll();
          _afterCreation(name, isActiveToolTarget: isTarget);
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    requestRepaintScene();
    return circle;
  }

  PointObject createIntersection(String obj1Id, String obj2Id) {
    final obj1 = data.graph.getObject(obj1Id);
    final obj2 = data.graph.getObject(obj2Id);
    final hasCircle = obj1 is CircleObject || obj2 is CircleObject;
    final isTarget = currentTool.value == HyperbolicTool.intersection;

    if (hasCircle) {
      final existing = data.graph.constraints
          .whereType<IntersectionConstraint>()
          .where(
            (c) =>
                (c.obj1Id == obj1Id && c.obj2Id == obj2Id) ||
                (c.obj1Id == obj2Id && c.obj2Id == obj1Id),
          )
          .toList();

      if (existing.isEmpty) {
        final id1 = nextObjectId('inter');
        final name1 = _nextNameForCreation('x1', isActiveToolTarget: isTarget);
        final pt1 = PointObject(
          id: id1,
          name: name1,
          color: currentColor.toARGB32(),
        );
        final c1 = IntersectionConstraint(
          id: 'c_$id1',
          obj1Id: obj1Id,
          obj2Id: obj2Id,
          pointId: id1,
          index: 0,
        );

        final id2 = nextObjectId('inter');
        final name2 = NameGuess.nextAvailableName(name1, [
          ...data.objects.map((o) => o.name),
          name1,
        ]);
        final pt2 = PointObject(
          id: id2,
          name: name2,
          color: currentColor.toARGB32(),
        );
        final c2 = IntersectionConstraint(
          id: 'c_$id2',
          obj1Id: obj1Id,
          obj2Id: obj2Id,
          pointId: id2,
          index: 1,
        );

        data.graph.addObject(pt1);
        data.graph.addConstraint(c1);
        data.graph.addObject(pt2);
        data.graph.addConstraint(c2);
        data.graph.evaluateAll();
        _afterCreation(name2, isActiveToolTarget: isTarget);

        undoManager.add(
          UndoCallback(
            'Add Intersections $name1, $name2',
            undoCallback: () {
              data.graph.removeObject(id2);
              data.graph.removeObject(id1);
              updateDefaultNameForCurrentTool();
              requestRepaintScene();
            },
            redoCallback: () {
              data.graph.addObject(pt1);
              data.graph.addConstraint(c1);
              data.graph.addObject(pt2);
              data.graph.addConstraint(c2);
              data.graph.evaluateAll();
              _afterCreation(name2, isActiveToolTarget: isTarget);
              requestRepaintScene();
            },
          ),
        );

        fileManager.maybeChange();
        requestRepaintScene();
        return pt1;
      } else if (existing.length == 1) {
        final first = existing.first;
        final nextIndex = first.index == 0 ? 1 : 0;
        final id = nextObjectId('inter');
        final name = _nextNameForCreation('x1', isActiveToolTarget: isTarget);
        final pt = PointObject(
          id: id,
          name: name,
          color: currentColor.toARGB32(),
        );
        final c = IntersectionConstraint(
          id: 'c_$id',
          obj1Id: first.obj1Id,
          obj2Id: first.obj2Id,
          pointId: id,
          index: nextIndex,
        );

        data.graph.addObject(pt);
        data.graph.addConstraint(c);
        data.graph.evaluateAll();
        _afterCreation(name, isActiveToolTarget: isTarget);

        undoManager.add(
          UndoCallback(
            'Add Intersection $name',
            undoCallback: () {
              data.graph.removeObject(id);
              updateDefaultNameForCurrentTool();
              requestRepaintScene();
            },
            redoCallback: () {
              data.graph.addObject(pt);
              data.graph.addConstraint(c);
              data.graph.evaluateAll();
              _afterCreation(name, isActiveToolTarget: isTarget);
              requestRepaintScene();
            },
          ),
        );

        fileManager.maybeChange();
        requestRepaintScene();
        return pt;
      }
    }

    final id = nextObjectId('inter');
    final name = _nextNameForCreation('x1', isActiveToolTarget: isTarget);
    final pt = PointObject(id: id, name: name, color: currentColor.toARGB32());
    final c = IntersectionConstraint(
      id: 'c_$id',
      obj1Id: obj1Id,
      obj2Id: obj2Id,
      pointId: id,
    );

    data.graph.addObject(pt);
    data.graph.addConstraint(c);
    data.graph.evaluateAll();
    _afterCreation(name, isActiveToolTarget: isTarget);

    undoManager.add(
      UndoCallback(
        'Add Intersection $name',
        undoCallback: () {
          data.graph.removeObject(id);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.addObject(pt);
          data.graph.addConstraint(c);
          data.graph.evaluateAll();
          _afterCreation(name, isActiveToolTarget: isTarget);
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    requestRepaintScene();
    return pt;
  }

  NumberObject createDistanceMeasurement(String p1Id, String p2Id) {
    final id = nextObjectId('dist');
    final isTarget = currentTool.value == HyperbolicTool.measureDistance;
    final name = _nextNameForCreation('d1', isActiveToolTarget: isTarget);
    final numObj = NumberObject(
      id: id,
      name: name,
      unit: NumberUnit.distance,
      min: 0.0,
      max: 10.0,
    );
    final c = DistanceMeasurementConstraint(
      id: 'c_$id',
      p1Id: p1Id,
      p2Id: p2Id,
      numberId: id,
    );

    data.graph.addObject(numObj);
    data.graph.addConstraint(c);
    data.graph.evaluateAll();
    _afterCreation(name, isActiveToolTarget: isTarget);

    undoManager.add(
      UndoCallback(
        'Measure Distance $name',
        undoCallback: () {
          data.graph.removeObject(id);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.addObject(numObj);
          data.graph.addConstraint(c);
          data.graph.evaluateAll();
          _afterCreation(name, isActiveToolTarget: isTarget);
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    requestRepaintScene();
    return numObj;
  }

  PointObject createMidpoint(String p1Id, String p2Id) {
    final id = nextObjectId('pt');
    final isTarget = currentTool.value == HyperbolicTool.midpoint;
    final name = _nextNameForCreation('m1', isActiveToolTarget: isTarget);
    final pt = PointObject(id: id, name: name, color: currentColor.toARGB32());
    final c = MidpointConstraint(
      id: 'c_$id',
      p1Id: p1Id,
      p2Id: p2Id,
      pointId: id,
    );

    data.graph.addObject(pt);
    data.graph.addConstraint(c);
    data.graph.evaluateAll();
    _afterCreation(name, isActiveToolTarget: isTarget);

    undoManager.add(
      UndoCallback(
        'Add Midpoint $name',
        undoCallback: () {
          data.graph.removeObject(id);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.addObject(pt);
          data.graph.addConstraint(c);
          data.graph.evaluateAll();
          _afterCreation(name, isActiveToolTarget: isTarget);
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    if (!isTarget) {
      selected = pt;
    }
    requestRepaintScene();
    return pt;
  }

  LineObject createPerpendicularLine(String baseLineId, String pointId) {
    final id = nextObjectId('line');
    final isTarget = currentTool.value == HyperbolicTool.perpendicular;
    final name = _nextNameForCreation('l1', isActiveToolTarget: isTarget);
    final line = LineObject(
      id: id,
      name: name,
      lineStyle: LineStyle.fullLine,
      color: currentColor.toARGB32(),
    );
    final c = PerpendicularLineConstraint(
      id: 'c_$id',
      baseLineId: baseLineId,
      pointId: pointId,
      lineId: id,
    );

    data.graph.addObject(line);
    data.graph.addConstraint(c);
    data.graph.evaluateAll();
    _afterCreation(name, isActiveToolTarget: isTarget);

    undoManager.add(
      UndoCallback(
        'Add Perpendicular $name',
        undoCallback: () {
          data.graph.removeObject(id);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.addObject(line);
          data.graph.addConstraint(c);
          data.graph.evaluateAll();
          _afterCreation(name, isActiveToolTarget: isTarget);
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    if (!isTarget) {
      selected = line;
    }
    requestRepaintScene();
    return line;
  }

  LineObject createPerpendicularBisector(String p1Id, String p2Id) {
    final id = nextObjectId('line');
    final isTarget = currentTool.value == HyperbolicTool.perpendicularBisector;
    final name = _nextNameForCreation('l1', isActiveToolTarget: isTarget);
    final line = LineObject(
      id: id,
      name: name,
      lineStyle: LineStyle.fullLine,
      color: currentColor.toARGB32(),
    );
    final c = PerpendicularBisectorConstraint(
      id: 'c_$id',
      p1Id: p1Id,
      p2Id: p2Id,
      lineId: id,
    );

    data.graph.addObject(line);
    data.graph.addConstraint(c);
    data.graph.evaluateAll();
    _afterCreation(name, isActiveToolTarget: isTarget);

    undoManager.add(
      UndoCallback(
        'Add Perp. Bisector $name',
        undoCallback: () {
          data.graph.removeObject(id);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.addObject(line);
          data.graph.addConstraint(c);
          data.graph.evaluateAll();
          _afterCreation(name, isActiveToolTarget: isTarget);
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    if (!isTarget) {
      selected = line;
    }
    requestRepaintScene();
    return line;
  }

  LineObject createAngleBisector(String p1Id, String vertexId, String p2Id) {
    final id = nextObjectId('line');
    final isTarget = currentTool.value == HyperbolicTool.angleBisector;
    final name = _nextNameForCreation('r1', isActiveToolTarget: isTarget);
    final line = LineObject(
      id: id,
      name: name,
      lineStyle: LineStyle.ray,
      color: currentColor.toARGB32(),
    );
    final c = AngleBisectorConstraint(
      id: 'c_$id',
      p1Id: p1Id,
      vertexId: vertexId,
      p2Id: p2Id,
      lineId: id,
    );

    data.graph.addObject(line);
    data.graph.addConstraint(c);
    data.graph.evaluateAll();
    _afterCreation(name, isActiveToolTarget: isTarget);

    undoManager.add(
      UndoCallback(
        'Add Angle Bisector $name',
        undoCallback: () {
          data.graph.removeObject(id);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.addObject(line);
          data.graph.addConstraint(c);
          data.graph.evaluateAll();
          _afterCreation(name, isActiveToolTarget: isTarget);
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    if (!isTarget) {
      selected = line;
    }
    requestRepaintScene();
    return line;
  }

  CircleObject createCircleWithRadius(String centerId, String radiusNumberId) {
    final id = nextObjectId('circ');
    final isTarget = currentTool.value == HyperbolicTool.circleRadius;
    final name = _nextNameForCreation('c1', isActiveToolTarget: isTarget);
    final circle = CircleObject(
      id: id,
      name: name,
      color: currentColor.toARGB32(),
    );
    final c = CircleCenterRadiusConstraint(
      id: 'c_$id',
      centerId: centerId,
      radiusNumberId: radiusNumberId,
      circleId: id,
    );

    data.graph.addObject(circle);
    data.graph.addConstraint(c);
    data.graph.evaluateAll();
    _afterCreation(name, isActiveToolTarget: isTarget);

    undoManager.add(
      UndoCallback(
        'Add Circle $name',
        undoCallback: () {
          data.graph.removeObject(id);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.addObject(circle);
          data.graph.addConstraint(c);
          data.graph.evaluateAll();
          _afterCreation(name, isActiveToolTarget: isTarget);
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    if (!isTarget) {
      selected = circle;
    }
    requestRepaintScene();
    return circle;
  }

  CircleObject createCompassCircle(String centerId, String p1Id, String p2Id) {
    final id = nextObjectId('circ');
    final isTarget = currentTool.value == HyperbolicTool.compass;
    final name = _nextNameForCreation('c1', isActiveToolTarget: isTarget);
    final circle = CircleObject(
      id: id,
      name: name,
      color: currentColor.toARGB32(),
    );
    final c = CompassCircleConstraint(
      id: 'c_$id',
      centerId: centerId,
      p1Id: p1Id,
      p2Id: p2Id,
      circleId: id,
    );

    data.graph.addObject(circle);
    data.graph.addConstraint(c);
    data.graph.evaluateAll();
    _afterCreation(name, isActiveToolTarget: isTarget);

    undoManager.add(
      UndoCallback(
        'Add Compass Circle $name',
        undoCallback: () {
          data.graph.removeObject(id);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.addObject(circle);
          data.graph.addConstraint(c);
          data.graph.evaluateAll();
          _afterCreation(name, isActiveToolTarget: isTarget);
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    if (!isTarget) {
      selected = circle;
    }
    requestRepaintScene();
    return circle;
  }

  PointObject createEquilateralTriangle(String p1Id, String p2Id) {
    final p1 = data.graph.getPoint(p1Id);
    final p2 = data.graph.getPoint(p2Id);
    if (p1 == null || p2 == null) return p1 ?? PointObject(id: '', name: '');

    final now = '${DateTime.now().microsecondsSinceEpoch}_${++_idCounter}';
    final idC = 'pt_${now}_c';
    final isTarget = currentTool.value == HyperbolicTool.equilateralTriangle;
    final nameC = _nextNameForCreation('p1', isActiveToolTarget: isTarget);
    final ptC = PointObject(
      id: idC,
      name: nameC,
      color: currentColor.toARGB32(),
    );
    final cC = EquilateralPointConstraint(
      id: 'c_$idC',
      p1Id: p1Id,
      p2Id: p2Id,
      pointId: idC,
    );

    // Check if a base segment between p1 and p2 already exists
    final bool hasBaseSegment = data.graph.constraints
        .whereType<LineThroughPointsConstraint>()
        .any((c) {
          final isEndpoints =
              (c.p1Id == p1Id && c.p2Id == p2Id) ||
              (c.p1Id == p2Id && c.p2Id == p1Id);
          if (!isEndpoints) return false;
          final lineObj = data.graph.getLine(c.lineId);
          return lineObj != null && lineObj.lineStyle == LineStyle.segment;
        });

    LineObject? segAB;
    LineThroughPointsConstraint? cAB;
    final usedNames = <String>[...data.objects.map((o) => o.name), nameC];

    if (!hasBaseSegment) {
      final idAB = 'line_${now}_ab';
      final nameAB = NameGuess.nextAvailableName('s1', usedNames);
      usedNames.add(nameAB);
      segAB = LineObject(
        id: idAB,
        name: nameAB,
        lineStyle: LineStyle.segment,
        color: currentColor.toARGB32(),
      );
      cAB = LineThroughPointsConstraint(
        id: 'c_$idAB',
        p1Id: p1Id,
        p2Id: p2Id,
        lineId: idAB,
      );
    }

    final idAC = 'line_${now}_ac';
    final nameAC = NameGuess.nextAvailableName('s1', usedNames);
    usedNames.add(nameAC);
    final segAC = LineObject(
      id: idAC,
      name: nameAC,
      lineStyle: LineStyle.segment,
      color: currentColor.toARGB32(),
    );
    final cAC = LineThroughPointsConstraint(
      id: 'c_$idAC',
      p1Id: p1Id,
      p2Id: idC,
      lineId: idAC,
    );

    final idBC = 'line_${now}_bc';
    final nameBC = NameGuess.nextAvailableName('s1', usedNames);
    final segBC = LineObject(
      id: idBC,
      name: nameBC,
      lineStyle: LineStyle.segment,
      color: currentColor.toARGB32(),
    );
    final cBC = LineThroughPointsConstraint(
      id: 'c_$idBC',
      p1Id: p2Id,
      p2Id: idC,
      lineId: idBC,
    );

    data.graph.addObject(ptC);
    data.graph.addConstraint(cC);
    if (segAB != null && cAB != null) {
      data.graph.addObject(segAB);
      data.graph.addConstraint(cAB);
    }
    data.graph.addObject(segAC);
    data.graph.addConstraint(cAC);
    data.graph.addObject(segBC);
    data.graph.addConstraint(cBC);
    data.graph.evaluateAll();
    _afterCreation(nameC, isActiveToolTarget: isTarget);

    undoManager.add(
      UndoCallback(
        'Add Equilateral Triangle $nameC',
        undoCallback: () {
          data.graph.removeObject(idBC);
          data.graph.removeObject(idAC);
          if (segAB != null) {
            data.graph.removeObject(segAB.id);
          }
          data.graph.removeObject(idC);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.addObject(ptC);
          data.graph.addConstraint(cC);
          if (segAB != null && cAB != null) {
            data.graph.addObject(segAB);
            data.graph.addConstraint(cAB);
          }
          data.graph.addObject(segAC);
          data.graph.addConstraint(cAC);
          data.graph.addObject(segBC);
          data.graph.addConstraint(cBC);
          data.graph.evaluateAll();
          _afterCreation(nameC, isActiveToolTarget: isTarget);
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    if (!isTarget) {
      selected = ptC;
    }
    requestRepaintScene();
    return ptC;
  }

  NumberObject createAngleMeasurement(String p1Id, String vId, String p2Id) {
    final id = nextObjectId('ang');
    final isTarget = currentTool.value == HyperbolicTool.measureAngle;
    final name = _nextNameForCreation('α 1', isActiveToolTarget: isTarget);
    final numObj = NumberObject(
      id: id,
      name: name,
      unit: NumberUnit.angleRadians,
      min: 0.0,
      max: math.pi,
    );
    final c = AngleMeasurementConstraint(
      id: 'c_$id',
      p1Id: p1Id,
      vertexId: vId,
      p2Id: p2Id,
      numberId: id,
    );

    data.graph.addObject(numObj);
    data.graph.addConstraint(c);
    data.graph.evaluateAll();
    _afterCreation(name, isActiveToolTarget: isTarget);

    undoManager.add(
      UndoCallback(
        'Measure Angle $name',
        undoCallback: () {
          data.graph.removeObject(id);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.addObject(numObj);
          data.graph.addConstraint(c);
          data.graph.evaluateAll();
          _afterCreation(name, isActiveToolTarget: isTarget);
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    requestRepaintScene();
    return numObj;
  }

  NumberObject createCoordinateMeasurement(String pointId, String coordinate) {
    final id = nextObjectId('coord');
    final expectedTool = coordinate == 'y'
        ? HyperbolicTool.measureCoordinateY
        : HyperbolicTool.measureCoordinateX;
    final isTarget = currentTool.value == expectedTool;
    final prefix = coordinate == 'y' ? 'y1' : 'x1';
    final name = _nextNameForCreation(prefix, isActiveToolTarget: isTarget);
    final numObj = NumberObject(
      id: id,
      name: name,
      unit: NumberUnit.coordinate,
      min: -1.0,
      max: 1.0,
      color: currentColor.toARGB32(),
    );
    final c = CoordinateMeasurementConstraint(
      id: 'c_$id',
      pointId: pointId,
      numberId: id,
      coordinate: coordinate,
    );

    data.graph.addObject(numObj);
    data.graph.addConstraint(c);
    data.graph.evaluateAll();
    _afterCreation(name, isActiveToolTarget: isTarget);

    undoManager.add(
      UndoCallback(
        'Measure ${coordinate.toUpperCase()} $name',
        undoCallback: () {
          data.graph.removeObject(id);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.addObject(numObj);
          data.graph.addConstraint(c);
          data.graph.evaluateAll();
          _afterCreation(name, isActiveToolTarget: isTarget);
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    if (!isTarget) {
      selected = numObj;
    }
    requestRepaintScene();
    return numObj;
  }

  bool get canExtendSelected =>
      selected is LineObject &&
      (selected as LineObject).lineStyle != LineStyle.fullLine;

  void extendSelectedLine() {
    final sel = selected;
    if (sel is LineObject && sel.lineStyle != LineStyle.fullLine) {
      extendLine(sel);
    }
  }

  void extendLine(LineObject lineObj) {
    if (lineObj.lineStyle == LineStyle.fullLine) return;
    final oldStyle = lineObj.lineStyle;
    undoManager.add(
      Change<LineStyle>(
        'Extend ${lineObj.name} to Line',
        oldStyle,
        LineStyle.fullLine,
        (style) {
          lineObj.lineStyle = style;
          fileManager.maybeChange();
          requestRepaintScene();
        },
      ),
    );
  }

  void toggleLockSelected() {
    if (selected == null) return;
    final obj = selected!;
    final prev = obj.locked;
    obj.locked = !prev;

    undoManager.add(
      UndoCallback(
        '${obj.locked ? "Lock" : "Unlock"} ${obj.name}',
        undoCallback: () {
          obj.locked = prev;
          requestRepaintScene();
        },
        redoCallback: () {
          obj.locked = !prev;
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    requestRepaintScene();
  }

  void deleteSelected() {
    if (selected == null) return;
    final obj = selected!;
    final id = obj.id;
    final removedConstraints = data.graph.constraints
        .where((c) => c.inputIds.contains(id) || c.outputIds.contains(id))
        .toList();

    selected = null;

    undoManager.add(
      UndoCallback(
        'Delete ${obj.name}',
        undoCallback: () {
          data.graph.addObject(obj);
          for (final c in removedConstraints) {
            data.graph.addConstraint(c);
          }
          data.graph.evaluateAll();
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
        redoCallback: () {
          data.graph.removeObject(id);
          updateDefaultNameForCurrentTool();
          requestRepaintScene();
        },
      ),
    );

    fileManager.maybeChange();
    requestRepaintScene();
  }

  // --- Hit Testing ---

  SceneObject? hitTest(Offset screenPos) {
    // 1. Points have highest hit priority:
    for (final pt in data.objects.whereType<PointObject>().toList().reversed) {
      if (!pt.visible) continue;
      final ptScreen = transform.diskToScreen(pt.point);
      if ((ptScreen - screenPos).distance <= 14.0) {
        return pt;
      }
    }

    // 2. Lines:
    for (final line in data.objects.whereType<LineObject>().toList().reversed) {
      if (!line.visible || line.line == null) continue;
      final diskPt = transform.screenToDisk(screenPos);
      if (diskPt.magnitudeSquared < 1.0) {
        if (line.line!.containsPoint(diskPt, eps: 0.04)) {
          return line;
        }
      }
    }

    // 3. Circles:
    for (final circ
        in data.objects.whereType<CircleObject>().toList().reversed) {
      if (!circ.visible || circ.circle == null) continue;
      final diskPt = transform.screenToDisk(screenPos);
      if (diskPt.magnitudeSquared < 1.0) {
        final d = circ.circle!.hyperbolicCenter.hyperbolicDistance(diskPt);
        if ((d - circ.circle!.hyperbolicRadius).abs() < 0.08) {
          return circ;
        }
      }
    }

    return null;
  }

  // --- Edit Actions ---
  void cut() {
    copy();
    deleteSelected();
  }

  void copy() {
    if (selected == null) return;
    final obj = selected!;
    _copiedObjectJson = obj.toJson();
    _copiedConstraintJsons = data.graph.constraints
        .where((c) => c.outputIds.contains(obj.id))
        .map((c) => c.toJson())
        .toList();
    final encoder = const JsonEncoder.withIndent('  ');
    final text = encoder.convert(_copiedObjectJson);
    Clipboard.setData(ClipboardData(text: text));
    undoManager.rebuildMenu();
  }

  void paste() {
    if (_copiedObjectJson == null) return;
    final parsed = parseSceneObject(_copiedObjectJson!);

    // If the original object was deleted (e.g. via Cut) and its defining
    // constraints' inputs still exist in the graph, restore it in place.
    if (data.graph.getObject(parsed.id) == null &&
        _copiedConstraintJsons.isNotEmpty) {
      final restoredConstraints = _copiedConstraintJsons
          .map(parseConstraint)
          .whereType<Constraint>()
          .toList();
      final inputsExist = restoredConstraints.every(
        (c) => c.inputIds.every((id) => data.graph.getObject(id) != null),
      );
      if (inputsExist) {
        data.graph.addObject(parsed);
        for (final c in restoredConstraints) {
          data.graph.addConstraint(c);
        }
        data.graph.evaluateAll();
        selected = parsed;
        undoManager.add(
          UndoCallback(
            'Paste ${parsed.name}',
            undoCallback: () {
              data.graph.removeObject(parsed.id);
              requestRepaintScene();
            },
            redoCallback: () {
              data.graph.addObject(parsed);
              for (final c in restoredConstraints) {
                data.graph.addConstraint(c);
              }
              data.graph.evaluateAll();
              selected = parsed;
              requestRepaintScene();
            },
          ),
        );
        fileManager.maybeChange();
        requestRepaintScene();
        return;
      }
    }

    if (parsed is PointObject) {
      HyperbolicPoint pos = parsed.point;
      final collision = data.objects.whereType<PointObject>().any(
        (p) => p.point.euclideanDistance(pos) < 1e-4,
      );
      if (collision) {
        var candidate = HyperbolicPoint(pos.x + 0.08, pos.y + 0.08);
        if (candidate.magnitudeSquared >= 0.95) {
          candidate = HyperbolicPoint(pos.x - 0.08, pos.y - 0.08);
        }
        if (candidate.magnitudeSquared < 0.98) {
          pos = candidate;
        }
      }
      final id = nextObjectId('pt');
      final name = NameGuess.nextAvailableName(
        parsed.name.isNotEmpty ? parsed.name : 'p1',
        data.objects.map((o) => o.name),
      );
      final pt = PointObject(
        id: id,
        name: name,
        point: pos,
        color: parsed.color,
      );
      final c = FreePointConstraint(id: 'c_$id', pointId: id);
      data.graph.addObject(pt);
      data.graph.addConstraint(c);
      data.graph.evaluateAll();
      selected = pt;
      undoManager.add(
        UndoCallback(
          'Paste Point $name',
          undoCallback: () {
            data.graph.removeObject(id);
            updateDefaultNameForCurrentTool();
            requestRepaintScene();
          },
          redoCallback: () {
            data.graph.addObject(pt);
            data.graph.addConstraint(c);
            data.graph.evaluateAll();
            selected = pt;
            updateDefaultNameForCurrentTool();
            requestRepaintScene();
          },
        ),
      );
      fileManager.maybeChange();
      requestRepaintScene();
    } else if (parsed is NumberObject) {
      final id = nextObjectId('num');
      final name = NameGuess.nextAvailableName(
        parsed.name.isNotEmpty ? parsed.name : 'r1',
        data.objects.map((o) => o.name),
      );
      final numObj = NumberObject(
        id: id,
        name: name,
        value: parsed.value,
        min: parsed.min,
        max: parsed.max,
        unit: parsed.unit,
        color: parsed.color,
      );
      data.graph.addObject(numObj);
      selected = numObj;
      undoManager.add(
        UndoCallback(
          'Paste Parameter $name',
          undoCallback: () {
            data.graph.removeObject(id);
            requestRepaintScene();
          },
          redoCallback: () {
            data.graph.addObject(numObj);
            selected = numObj;
            requestRepaintScene();
          },
        ),
      );
      fileManager.maybeChange();
      requestRepaintScene();
    }
  }

  void delete() => deleteSelected();

  Map<String, dynamic> toJson() => data.toJson();

  void updateSettings() {
    requestRepaintScene();
  }

  static void initSettings(Settings settings) {
    settings.add(colorList);
  }

  static void initDebugSettings(Settings settings) {}

  void dispose() {
    currentTool.removeListener(updateDefaultNameForCurrentTool);
    currentName.dispose();
    data.dispose();
  }
}
