import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../constraints/constraints.dart';
import '../objects/objects.dart';
import '../scene/scene_view.dart';
import '../transform.dart';

/// Base class for all step directives in a tutorial.
abstract class TutorialDirective {
  String get highlightId;
  String highlightIdFor(SceneView scene) => highlightId;
  bool get isSetupAction => false;
  bool get canDoItForMe => false;

  bool isSatisfied(SceneView scene);
  String statusText(SceneView scene);
  void onStepStart(SceneView scene) {}
  void applyDoItForMe(SceneView scene) {}
}

/// A directive that requires the user to click Continue on the tutorial card.
class AcknowledgeDirective extends TutorialDirective {
  @override
  String get highlightId => 'card.ok';

  @override
  bool isSatisfied(SceneView scene) => false;

  @override
  String statusText(SceneView scene) => 'Click Continue to proceed.';
}

/// A setup directive that resets the canvas to an empty state.
class ResetDirective extends TutorialDirective {
  @override
  String get highlightId => 'canvas.main';

  @override
  bool get isSetupAction => true;

  @override
  bool isSatisfied(SceneView scene) => true;

  @override
  String statusText(SceneView scene) => 'Scene reset.';

  @override
  void onStepStart(SceneView scene) {
    scene.data.clear();
    scene.requestRepaintScene();
  }
}

/// Setup action model describing an object to construct.
abstract class SetupItem {
  void apply(SceneView scene);
}

class SetupPointItem extends SetupItem {
  final String name;
  final double x;
  final double y;
  final bool locked;

  SetupPointItem({
    required this.name,
    required this.x,
    required this.y,
    this.locked = false,
  });

  @override
  void apply(SceneView scene) {
    final id = 'pt_${name}_${DateTime.now().microsecondsSinceEpoch}';
    final pt = PointObject(
      id: id,
      name: name,
      point: HyperbolicPoint(x, y),
      locked: locked,
    );
    scene.data.graph.addObject(pt);
    scene.data.graph.addConstraint(
      FreePointConstraint(id: 'c_$id', pointId: id),
    );
  }
}

class SetupLineItem extends SetupItem {
  final String name;
  final String p1Name;
  final String p2Name;
  final LineStyle style;

  SetupLineItem({
    required this.name,
    required this.p1Name,
    required this.p2Name,
    this.style = LineStyle.fullLine,
  });

  @override
  void apply(SceneView scene) {
    final p1 = scene.data.objects.whereType<PointObject>().firstWhere(
      (p) => p.name == p1Name || p.id == p1Name,
    );
    final p2 = scene.data.objects.whereType<PointObject>().firstWhere(
      (p) => p.name == p2Name || p.id == p2Name,
    );

    final id = 'ln_${name}_${DateTime.now().microsecondsSinceEpoch}';
    final line = LineObject(
      id: id,
      name: name,
      p1: p1.point,
      p2: p2.point,
      lineStyle: style,
    );
    scene.data.graph.addObject(line);
    scene.data.graph.addConstraint(
      LineThroughPointsConstraint(
        id: 'c_$id',
        p1Id: p1.id,
        p2Id: p2.id,
        lineId: id,
      ),
    );
  }
}

class SetupCircleItem extends SetupItem {
  final String name;
  final String centerName;
  final String pointName;

  SetupCircleItem({
    required this.name,
    required this.centerName,
    required this.pointName,
  });

  @override
  void apply(SceneView scene) {
    final center = scene.data.objects.whereType<PointObject>().firstWhere(
      (p) => p.name == centerName || p.id == centerName,
    );
    final pt = scene.data.objects.whereType<PointObject>().firstWhere(
      (p) => p.name == pointName || p.id == pointName,
    );

    final id = 'circ_${name}_${DateTime.now().microsecondsSinceEpoch}';
    final radius = center.point.hyperbolicDistance(pt.point);
    final circle = CircleObject(
      id: id,
      name: name,
      circle: HyperbolicCircle(
        hyperbolicCenter: center.point,
        hyperbolicRadius: radius,
      ),
    );
    scene.data.graph.addObject(circle);
    scene.data.graph.addConstraint(
      CircleCenterPointConstraint(
        id: 'c_$id',
        centerId: center.id,
        pointOnCircleId: pt.id,
        circleId: id,
      ),
    );
  }
}

class SetupNumberItem extends SetupItem {
  final String name;
  final double value;

  SetupNumberItem({required this.name, required this.value});

  @override
  void apply(SceneView scene) {
    final id = 'num_${name}_${DateTime.now().microsecondsSinceEpoch}';
    final numObj = NumberObject(id: id, name: name, value: value);
    scene.data.graph.addObject(numObj);
  }
}

/// Setup directive executing inline scene population.
class SetupDirective extends TutorialDirective {
  final List<SetupItem> items;

  SetupDirective(this.items);

  @override
  String get highlightId => 'canvas.main';

  @override
  bool get isSetupAction => true;

  @override
  bool isSatisfied(SceneView scene) => true;

  @override
  String statusText(SceneView scene) => 'Objects configured.';

  @override
  void onStepStart(SceneView scene) {
    for (final item in items) {
      item.apply(scene);
    }
    scene.data.graph.evaluateAll();
    scene.requestRepaintScene();
  }
}

/// Directive requiring a specific tool to be selected in the toolbar.
class ToolDirective extends TutorialDirective {
  final HyperbolicTool targetTool;

  ToolDirective(this.targetTool);

  @override
  String get highlightId => 'tool.${targetTool.name}';

  @override
  bool get canDoItForMe => true;

  @override
  bool isSatisfied(SceneView scene) => scene.currentTool.value == targetTool;

  @override
  String statusText(SceneView scene) =>
      'Select ${targetTool.label} tool  (Current: ${scene.currentTool.value.label})';

  @override
  void applyDoItForMe(SceneView scene) {
    scene.currentTool.value = targetTool;
  }
}

/// Directive requiring the user to add a point near a specified location.
class AddPointDirective extends TutorialDirective {
  final HyperbolicPoint targetPoint;
  final String? targetName;
  final double tolerance;

  AddPointDirective({
    required this.targetPoint,
    this.targetName,
    this.tolerance = 0.3,
  });

  @override
  String get highlightId => 'canvas.point';

  @override
  bool get canDoItForMe => true;

  @override
  bool isSatisfied(SceneView scene) {
    for (final pt in scene.data.objects.whereType<PointObject>()) {
      if (targetName != null && pt.name == targetName) return true;
      if (pt.point.euclideanDistance(targetPoint) <= tolerance) return true;
    }
    return false;
  }

  @override
  String statusText(SceneView scene) =>
      'Click canvas near (${targetPoint.x.toStringAsFixed(2)}, ${targetPoint.y.toStringAsFixed(2)})';

  @override
  void applyDoItForMe(SceneView scene) {
    final pt = scene.createFreePoint(targetPoint);
    if (targetName != null) {
      pt.name = targetName!;
      scene.requestRepaintScene();
    }
  }
}

/// Directive requiring the user to select a specific object.
class SelectDirective extends TutorialDirective {
  final String targetName;

  SelectDirective(this.targetName);

  @override
  String get highlightId => 'object.$targetName';

  @override
  bool get canDoItForMe => true;

  @override
  bool isSatisfied(SceneView scene) =>
      scene.selected?.name == targetName || scene.selected?.id == targetName;

  @override
  String statusText(SceneView scene) =>
      'Select "$targetName"  (Current: ${scene.selected?.name ?? 'None'})';

  @override
  void applyDoItForMe(SceneView scene) {
    for (final obj in scene.data.objects) {
      if (obj.name == targetName || obj.id == targetName) {
        scene.selectObject(obj);
        break;
      }
    }
  }
}

/// Directive requiring the user to drag a point to a target coordinate.
class DragDirective extends TutorialDirective {
  final String targetName;
  final HyperbolicPoint targetPoint;
  final double tolerance;

  DragDirective({
    required this.targetName,
    required this.targetPoint,
    this.tolerance = 0.25,
  });

  @override
  String get highlightId => 'object.$targetName';

  @override
  bool get canDoItForMe => true;

  @override
  bool isSatisfied(SceneView scene) {
    for (final pt in scene.data.objects.whereType<PointObject>()) {
      if (pt.name == targetName || pt.id == targetName) {
        return pt.point.euclideanDistance(targetPoint) <= tolerance;
      }
    }
    return false;
  }

  @override
  String statusText(SceneView scene) {
    for (final pt in scene.data.objects.whereType<PointObject>()) {
      if (pt.name == targetName || pt.id == targetName) {
        final dist = pt.point.euclideanDistance(targetPoint);
        return 'Drag $targetName to (${targetPoint.x.toStringAsFixed(2)}, ${targetPoint.y.toStringAsFixed(2)}) (dist: ${dist.toStringAsFixed(2)})';
      }
    }
    return 'Drag $targetName to (${targetPoint.x.toStringAsFixed(2)}, ${targetPoint.y.toStringAsFixed(2)})';
  }

  @override
  void applyDoItForMe(SceneView scene) {
    for (final pt in scene.data.objects.whereType<PointObject>()) {
      if (pt.name == targetName || pt.id == targetName) {
        scene.data.graph.dragPoint(pt.id, targetPoint);
        scene.requestRepaintScene();
        break;
      }
    }
  }
}

/// Directive requiring a numeric slider to be set to a target value.
class SliderDirective extends TutorialDirective {
  final String targetName;
  final double targetValue;
  final double tolerance;

  SliderDirective({
    required this.targetName,
    required this.targetValue,
    this.tolerance = 0.15,
  });

  @override
  String get highlightId => 'slider.$targetName';

  @override
  bool get canDoItForMe => true;

  @override
  bool isSatisfied(SceneView scene) {
    for (final numObj in scene.data.objects.whereType<NumberObject>()) {
      if (numObj.name == targetName || numObj.id == targetName) {
        return (numObj.value - targetValue).abs() <= tolerance;
      }
    }
    return false;
  }

  @override
  String statusText(SceneView scene) {
    for (final numObj in scene.data.objects.whereType<NumberObject>()) {
      if (numObj.name == targetName || numObj.id == targetName) {
        return 'Set $targetName = ${targetValue.toStringAsFixed(2)}  (Current: ${numObj.value.toStringAsFixed(2)})';
      }
    }
    return 'Set $targetName = ${targetValue.toStringAsFixed(2)}';
  }

  @override
  void applyDoItForMe(SceneView scene) {
    for (final numObj in scene.data.objects.whereType<NumberObject>()) {
      if (numObj.name == targetName || numObj.id == targetName) {
        numObj.value = targetValue;
        scene.data.graph.evaluateAll();
        scene.requestRepaintScene();
        break;
      }
    }
  }
}

/// Model of a single step within a tutorial.
class TutorialStep {
  final int stepNumber;
  final String title;
  final String body;
  final List<TutorialDirective> directives;

  TutorialStep({
    required this.stepNumber,
    required this.title,
    required this.body,
    required this.directives,
  });

  bool isSatisfied(SceneView scene) {
    final interactive = directives.where((d) => !d.isSetupAction);
    if (interactive.isEmpty) return true;
    return interactive.every((d) => d.isSatisfied(scene));
  }

  String? highlightIdFor(SceneView scene) {
    for (final d in directives) {
      if (!d.isSetupAction && !d.isSatisfied(scene)) {
        return d.highlightIdFor(scene);
      }
    }
    return null;
  }

  bool get canDoItForMe =>
      directives.any((d) => !d.isSetupAction && d.canDoItForMe);

  void doItForMe(SceneView scene) {
    for (final d in directives) {
      if (!d.isSetupAction && d.canDoItForMe && !d.isSatisfied(scene)) {
        d.applyDoItForMe(scene);
      }
    }
  }

  void onStepStart(SceneView scene) {
    for (final d in directives) {
      d.onStepStart(scene);
    }
  }
}
