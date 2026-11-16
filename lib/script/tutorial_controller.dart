import 'package:flutter/foundation.dart';

import '../scene/scene_view.dart';
import '../transform.dart';
import 'tutorial_parser.dart';
import 'tutorial_step.dart';

/// Coordinates tutorial state, evaluates criteria, and drives step transitions.
class TutorialController extends ChangeNotifier {
  final SceneView scene;
  final Tutorial tutorial;
  int currentStepIndex = 0;
  bool isCompleted = false;

  TutorialController(this.scene, this.tutorial) {
    scene.currentTool.addListener(_checkCondition);
    scene.repaintCounter.addListener(_checkCondition);
    scene.undoManager.addListener(_checkCondition);
    _applyStepStart();
  }

  TutorialStep? get currentStep => (currentStepIndex < tutorial.steps.length)
      ? tutorial.steps[currentStepIndex]
      : null;

  String? get currentHighlightId => currentStep?.highlightIdFor(scene);

  /// If the current step highlights a recommended point on the canvas to place a point.
  HyperbolicPoint? get highlightedPoint {
    final step = currentStep;
    if (step == null || currentHighlightId != 'canvas.point') return null;
    for (final d in step.directives) {
      if (d is AddPointDirective && !d.isSatisfied(scene)) {
        return d.targetPoint;
      }
    }
    return null;
  }

  bool get isCurrentStepSatisfied =>
      currentStep != null && currentStep!.isSatisfied(scene);

  /// Whether the user can proceed to the next step.
  bool get isContinueEnabled {
    if (isCompleted || currentStep == null) return false;
    final isAcknowledge = currentStep!.directives.any(
      (d) => d is AcknowledgeDirective,
    );
    if (isAcknowledge) return true;
    return isCurrentStepSatisfied;
  }

  /// Whether "Do it for me" is available.
  bool get canDoItForMe =>
      tutorial.allowDoItForMe &&
      !isContinueEnabled &&
      (currentStep?.canDoItForMe ?? false);

  /// Automatically fulfills current step criteria.
  void doItForMe() {
    if (currentStep == null) return;
    currentStep!.doItForMe(scene);
    _checkCondition();
  }

  double get progress => tutorial.steps.isEmpty
      ? 1.0
      : (currentStepIndex + 1) / tutorial.steps.length;

  void _applyStepStart() {
    currentStep?.onStepStart(scene);
    _checkCondition();
  }

  void _checkCondition() {
    if (isCompleted || currentStep == null) return;
    notifyListeners();
  }

  void nextStep() {
    if (!isContinueEnabled && !isCompleted) return;
    if (currentStepIndex < tutorial.steps.length - 1) {
      currentStepIndex++;
      _applyStepStart();
      notifyListeners();
    } else {
      isCompleted = true;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStepIndex > 0) {
      currentStepIndex--;
      isCompleted = false;
      _applyStepStart();
      notifyListeners();
    }
  }

  void resetCurrentStep() {
    _applyStepStart();
    notifyListeners();
  }

  @override
  void dispose() {
    scene.currentTool.removeListener(_checkCondition);
    scene.repaintCounter.removeListener(_checkCondition);
    scene.undoManager.removeListener(_checkCondition);
    super.dispose();
  }
}
