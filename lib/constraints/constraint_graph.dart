import 'dart:math' as math;
import '../objects/objects.dart';
import '../transform.dart';
import 'circle_constraints.dart';
import 'constraint.dart';
import 'free_constraints.dart';
import 'intersection_constraints.dart';
import 'line_constraints.dart';
import 'measurement_constraints.dart';

/// Bipartite constraint graph managing geometric objects, numeric parameters,
/// topological forward evaluation, and the numerical inverse solver.
class ConstraintGraph implements ConstraintLookup {
  final Map<String, SceneObject> _objects = {};
  final Map<String, Constraint> _constraints = {};

  // Cached topological order of constraints
  List<Constraint>? _cachedTopologicalOrder;

  ConstraintGraph();

  List<SceneObject> get objects => _objects.values.toList();
  List<Constraint> get constraints => _constraints.values.toList();

  @override
  SceneObject? getObject(String id) => _objects[id];

  @override
  PointObject? getPoint(String id) => _objects[id] as PointObject?;

  @override
  LineObject? getLine(String id) => _objects[id] as LineObject?;

  @override
  CircleObject? getCircle(String id) => _objects[id] as CircleObject?;

  @override
  NumberObject? getNumber(String id) => _objects[id] as NumberObject?;

  void addObject(SceneObject obj) {
    _objects[obj.id] = obj;
    _invalidateTopology();
  }

  void removeObject(String id) {
    _objects.remove(id);
    // Remove any constraints that have this object as input or output
    final toRemove = _constraints.values
        .where((c) => c.inputIds.contains(id) || c.outputIds.contains(id))
        .map((c) => c.id)
        .toList();
    for (final cid in toRemove) {
      removeConstraint(cid);
    }
    _invalidateTopology();
  }

  void addConstraint(Constraint constraint) {
    _constraints[constraint.id] = constraint;
    for (final outId in constraint.outputIds) {
      final obj = _objects[outId];
      if (obj != null) {
        obj.constraintId = constraint.id;
      }
    }
    _invalidateTopology();
  }

  void removeConstraint(String id) {
    final constraint = _constraints.remove(id);
    if (constraint != null) {
      for (final outId in constraint.outputIds) {
        final obj = _objects[outId];
        if (obj != null && obj.constraintId == id) {
          obj.constraintId = null;
        }
      }
    }
    _invalidateTopology();
  }

  void clear() {
    _objects.clear();
    _constraints.clear();
    _invalidateTopology();
  }

  void _invalidateTopology() {
    _cachedTopologicalOrder = null;
  }

  /// Computes a topological ordering of all constraints in the DAG.
  List<Constraint> getTopologicalOrder() {
    if (_cachedTopologicalOrder != null) {
      return _cachedTopologicalOrder!;
    }

    // In-degree for each constraint:
    // A constraint C depends on constraint C_dep if an input of C is an output of C_dep.
    final Map<String, int> inDegree = {};
    final Map<String, List<String>> dependents = {};

    for (final c in _constraints.values) {
      inDegree[c.id] = 0;
      dependents[c.id] = [];
    }

    for (final c in _constraints.values) {
      for (final inId in c.inputIds) {
        final parentObj = _objects[inId];
        if (parentObj != null && parentObj.constraintId != null) {
          final parentCid = parentObj.constraintId!;
          if (_constraints.containsKey(parentCid) && parentCid != c.id) {
            inDegree[c.id] = (inDegree[c.id] ?? 0) + 1;
            dependents[parentCid]?.add(c.id);
          }
        }
      }
    }

    final queue = <String>[];
    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }

    final result = <Constraint>[];
    while (queue.isNotEmpty) {
      final cid = queue.removeAt(0);
      final c = _constraints[cid];
      if (c != null) {
        result.add(c);
      }

      for (final depCid in dependents[cid] ?? []) {
        inDegree[depCid] = (inDegree[depCid] ?? 1) - 1;
        if (inDegree[depCid] == 0) {
          queue.add(depCid);
        }
      }
    }

    // Fallback if cycles exist: append any missing constraints
    if (result.length < _constraints.length) {
      for (final c in _constraints.values) {
        if (!result.contains(c)) {
          result.add(c);
        }
      }
    }

    _cachedTopologicalOrder = result;
    return result;
  }

  /// Forward-evaluates all constraints in topological order.
  void evaluateAll() {
    final order = getTopologicalOrder();
    for (final c in order) {
      c.evaluate(this);
    }
  }

  /// Identifies all unlocked ancestor parameter objects that can be adjusted
  /// to move [targetObjectId].
  List<SceneObject> getUnlockedAncestorParams(String targetObjectId) {
    return getUnlockedAncestorParamsForObjects([targetObjectId]);
  }

  /// Identifies all unlocked ancestor parameter objects for [targetObjectIds],
  /// excluding any object IDs in [excludedIds].
  ///
  /// Seed objects in [targetObjectIds] are traversed into their generating
  /// constraints even if the seed object itself is marked `locked`, so callers
  /// can find unlocked ancestors capable of restoring a locked descendant.
  List<SceneObject> getUnlockedAncestorParamsForObjects(
    Iterable<String> targetObjectIds, {
    Set<String> excludedIds = const {},
  }) {
    final ancestors = <String>{};
    final visited = <String>{};
    final seedIds = targetObjectIds.toSet();

    void visit(String objId) {
      if (visited.contains(objId)) return;
      visited.add(objId);

      if (excludedIds.contains(objId)) return;

      final obj = _objects[objId];
      if (obj == null) return;

      if (obj.locked && !seedIds.contains(objId)) return;

      final cid = obj.constraintId;
      if (cid == null) {
        if (!obj.locked) {
          ancestors.add(objId);
        }
        return;
      }

      final c = _constraints[cid];
      if (c == null || c is FreePointConstraint) {
        if (!obj.locked) {
          ancestors.add(objId);
        }
        return;
      }

      for (final inId in c.inputIds) {
        visit(inId);
      }
    }

    for (final id in seedIds) {
      visit(id);
    }
    return ancestors.map((id) => _objects[id]!).toList();
  }

  List<_ResidualTarget> _captureLockedTargets() {
    final targets = <_ResidualTarget>[];
    for (final obj in _objects.values) {
      if (!obj.locked) continue;
      final cid = obj.constraintId;
      if (cid == null) continue;
      final c = _constraints[cid];
      if (c == null || c is FreePointConstraint) continue;

      if (obj is PointObject) {
        targets.add(_PointResidualTarget(obj, obj.point));
      } else if (obj is NumberObject) {
        targets.add(_NumberResidualTarget(obj, obj.value));
      } else if (obj is CircleObject && obj.circle != null) {
        targets.add(
          _CircleResidualTarget(
            obj,
            obj.circle!.hyperbolicCenter,
            obj.circle!.hyperbolicRadius,
          ),
        );
      } else if (obj is LineObject && obj.p1 != null && obj.p2 != null) {
        targets.add(_LineResidualTarget(obj, obj.p1!, obj.p2!));
      }
    }
    return targets;
  }

  List<IntersectionConstraint> _captureValidIntersections() {
    return _constraints.values
        .whereType<IntersectionConstraint>()
        .where((c) => c.computeIntersections(this).isNotEmpty)
        .toList();
  }

  bool _allIntersectionsValid(List<IntersectionConstraint> intersections) {
    for (final c in intersections) {
      if (c.computeIntersections(this).isEmpty) {
        return false;
      }
    }
    return true;
  }

  double _maxTargetError(List<_ResidualTarget> targets) {
    double maxErr = 0.0;
    for (final t in targets) {
      final err = t.maxAbsError();
      if (err > maxErr) maxErr = err;
    }
    return maxErr;
  }

  /// Numerical inverse solver: smoothly drags [pointObjectId] toward [targetPos]
  /// by taking damped least-squares (Jacobian) steps on unlocked ancestor
  /// parameters, while keeping locked descendants fixed and preserving active
  /// intersections.
  bool dragPoint(
    String pointObjectId,
    HyperbolicPoint targetPos, {
    int maxIterations = 12,
    double tolerance = 1e-4,
    double damping = 1e-3,
  }) {
    final targetPtObj = getPoint(pointObjectId);
    if (targetPtObj == null || targetPtObj.locked) return false;

    evaluateAll();
    final snapshot = _GraphSnapshot.capture(this);
    final initialPos = targetPtObj.point;
    final lockedTargets = _captureLockedTargets();
    final validIntersections = _captureValidIntersections();
    final double lockTol = tolerance;

    final safeTarget = targetPos.magnitudeSquared < 1.0
        ? targetPos
        : targetPos.normalized().scale(0.9999);

    final cid = targetPtObj.constraintId;
    final c = cid != null ? _constraints[cid] : null;
    final bool isFreePoint = cid == null || c is FreePointConstraint;

    if (isFreePoint) {
      bool tryMoveFreePoint(HyperbolicPoint candidate) {
        snapshot.restore(this);
        final clampedCandidate = candidate.magnitudeSquared < 1.0
            ? candidate
            : candidate.normalized().scale(0.9999);
        targetPtObj.point = clampedCandidate;
        evaluateAll();

        final driftedLocks = lockedTargets
            .where((t) => t.maxAbsError() > lockTol)
            .toList();
        if (driftedLocks.isNotEmpty) {
          final otherParams = getUnlockedAncestorParamsForObjects(
            driftedLocks.map((t) => t.objectId),
            excludedIds: {pointObjectId},
          );
          if (otherParams.isEmpty) {
            return false;
          }
          _solveResiduals(
            targets: lockedTargets,
            params: otherParams,
            maxIterations: maxIterations,
            tolerance: tolerance * 0.25,
            damping: damping,
          );
        }

        return _maxTargetError(lockedTargets) <= lockTol &&
            _allIntersectionsValid(validIntersections);
      }

      if (tryMoveFreePoint(safeTarget)) {
        return true;
      }

      // If no other unlocked ancestors could absorb the lock, try projecting
      // the dragged point itself onto the lock manifold (e.g. moving p1 along
      // a circle of locked distance around a locked p2).
      if (lockedTargets.isNotEmpty) {
        snapshot.restore(this);
        targetPtObj.point = safeTarget;
        evaluateAll();
        final driftedLocks = lockedTargets
            .where((t) => t.maxAbsError() > lockTol)
            .toList();
        final allParams = getUnlockedAncestorParamsForObjects(
          driftedLocks.map((t) => t.objectId),
        );
        if (allParams.isNotEmpty) {
          _solveResiduals(
            targets: lockedTargets,
            params: allParams,
            maxIterations: maxIterations,
            tolerance: tolerance * 0.25,
            damping: damping,
          );
          if (_maxTargetError(lockedTargets) <= lockTol &&
              _allIntersectionsValid(validIntersections)) {
            final movedDist = (targetPtObj.point - initialPos).magnitude;
            if (movedDist > lockTol * 5.0) {
              return true;
            }
          }
        }
      }

      // Binary-search along the segment from initialPos toward safeTarget so
      // the point moves toward what the user requested up to the lock/tangency
      // boundary.
      double low = 0.0;
      double high = 1.0;
      double bestAlpha = 0.0;
      for (int step = 0; step < 12; step++) {
        final mid = 0.5 * (low + high);
        final candidate = initialPos + (safeTarget - initialPos).scale(mid);
        if (tryMoveFreePoint(candidate)) {
          bestAlpha = mid;
          low = mid;
        } else {
          high = mid;
        }
      }

      if (bestAlpha > 1e-3) {
        final bestCandidate =
            initialPos + (safeTarget - initialPos).scale(bestAlpha);
        if (tryMoveFreePoint(bestCandidate) &&
            (targetPtObj.point - initialPos).magnitude > lockTol * 5.0) {
          return true;
        }
      }

      snapshot.restore(this);
      evaluateAll();
      return false;
    }

    // Constrained point: find unlocked ancestor parameters
    final params = getUnlockedAncestorParamsForObjects([pointObjectId]);
    if (params.isEmpty) return false;

    bool tryMoveConstrainedPoint(HyperbolicPoint candidate) {
      snapshot.restore(this);
      final clampedCandidate = candidate.magnitudeSquared < 1.0
          ? candidate
          : candidate.normalized().scale(0.9999);

      final solveTargets = <_ResidualTarget>[
        _PointResidualTarget(targetPtObj, clampedCandidate),
        ...lockedTargets.map((t) => t.withWeight(4.0)),
      ];
      final solveParams = <SceneObject>{
        ...params,
        ...getUnlockedAncestorParamsForObjects(
          lockedTargets.map((t) => t.objectId),
        ),
      }.toList();

      _solveResiduals(
        targets: solveTargets,
        params: solveParams,
        maxIterations: maxIterations,
        tolerance: tolerance,
        damping: damping,
      );

      // If any locked target still exceeds tolerance, polish locked targets.
      if (_maxTargetError(lockedTargets) > lockTol) {
        _solveResiduals(
          targets: lockedTargets,
          params: solveParams,
          maxIterations: maxIterations,
          tolerance: tolerance,
          damping: damping,
        );
      }

      return _maxTargetError(lockedTargets) <= lockTol &&
          _allIntersectionsValid(validIntersections);
    }

    if (tryMoveConstrainedPoint(safeTarget)) {
      return (targetPtObj.point - initialPos).magnitude > 1e-5 ||
          (safeTarget - initialPos).magnitude <= 1e-5;
    }

    double low = 0.0;
    double high = 1.0;
    double bestAlpha = 0.0;
    for (int step = 0; step < 12; step++) {
      final mid = 0.5 * (low + high);
      final candidate = initialPos + (safeTarget - initialPos).scale(mid);
      if (tryMoveConstrainedPoint(candidate)) {
        bestAlpha = mid;
        low = mid;
      } else {
        high = mid;
      }
    }

    if (bestAlpha > 1e-4) {
      final bestCandidate =
          initialPos + (safeTarget - initialPos).scale(bestAlpha);
      tryMoveConstrainedPoint(bestCandidate);
      return true;
    }

    snapshot.restore(this);
    evaluateAll();
    return false;
  }

  /// Sets or solves [numberObjectId] toward [targetValue] while respecting
  /// locked descendants and active intersections.
  bool setNumberValue(
    String numberObjectId,
    double targetValue, {
    int maxIterations = 12,
    double tolerance = 1e-4,
    double damping = 1e-3,
  }) {
    final numObj = getNumber(numberObjectId);
    if (numObj == null || numObj.locked) return false;

    evaluateAll();
    final snapshot = _GraphSnapshot.capture(this);
    final double initialVal = numObj.value;
    final double safeTarget = targetValue.clamp(numObj.min, numObj.max);
    final lockedTargets = _captureLockedTargets();
    final validIntersections = _captureValidIntersections();
    final double lockTol = tolerance;

    final cid = numObj.constraintId;
    final c = cid != null ? _constraints[cid] : null;
    final bool isFreeNumber = cid == null || c == null;

    if (isFreeNumber) {
      bool trySetFreeNumber(double candidate) {
        snapshot.restore(this);
        numObj.value = candidate.clamp(numObj.min, numObj.max);
        evaluateAll();

        final driftedLocks = lockedTargets
            .where((t) => t.maxAbsError() > lockTol)
            .toList();
        if (driftedLocks.isNotEmpty) {
          final otherParams = getUnlockedAncestorParamsForObjects(
            driftedLocks.map((t) => t.objectId),
            excludedIds: {numberObjectId},
          );
          if (otherParams.isEmpty) {
            return false;
          }
          _solveResiduals(
            targets: lockedTargets,
            params: otherParams,
            maxIterations: maxIterations,
            tolerance: tolerance * 0.25,
            damping: damping,
          );
        }

        return _maxTargetError(lockedTargets) <= lockTol &&
            _allIntersectionsValid(validIntersections);
      }

      if (trySetFreeNumber(safeTarget)) {
        return true;
      }

      double low = 0.0;
      double high = 1.0;
      double bestAlpha = 0.0;
      for (int step = 0; step < 12; step++) {
        final mid = 0.5 * (low + high);
        final candidate = initialVal + (safeTarget - initialVal) * mid;
        if (trySetFreeNumber(candidate)) {
          bestAlpha = mid;
          low = mid;
        } else {
          high = mid;
        }
      }

      if (bestAlpha > 1e-3) {
        final bestCandidate =
            initialVal + (safeTarget - initialVal) * bestAlpha;
        if (trySetFreeNumber(bestCandidate) &&
            (numObj.value - initialVal).abs() > lockTol * 5.0) {
          return true;
        }
      }

      snapshot.restore(this);
      evaluateAll();
      return false;
    }

    // Constrained number (measurement): solve via unlocked ancestors
    final params = getUnlockedAncestorParamsForObjects([numberObjectId]);
    if (params.isEmpty) return false;

    bool trySolveConstrainedNumber(double candidate) {
      snapshot.restore(this);
      final solveTargets = <_ResidualTarget>[
        _NumberResidualTarget(numObj, candidate),
        ...lockedTargets.map((t) => t.withWeight(4.0)),
      ];
      final solveParams = <SceneObject>{
        ...params,
        ...getUnlockedAncestorParamsForObjects(
          lockedTargets.map((t) => t.objectId),
        ),
      }.toList();

      _solveResiduals(
        targets: solveTargets,
        params: solveParams,
        maxIterations: maxIterations,
        tolerance: tolerance,
        damping: damping,
      );

      if (_maxTargetError(lockedTargets) > lockTol) {
        _solveResiduals(
          targets: lockedTargets,
          params: solveParams,
          maxIterations: maxIterations,
          tolerance: tolerance,
          damping: damping,
        );
      }

      return _maxTargetError(lockedTargets) <= lockTol &&
          _allIntersectionsValid(validIntersections);
    }

    if (trySolveConstrainedNumber(safeTarget)) {
      return (numObj.value - initialVal).abs() > 1e-5 ||
          (safeTarget - initialVal).abs() <= 1e-5;
    }

    double low = 0.0;
    double high = 1.0;
    double bestAlpha = 0.0;
    for (int step = 0; step < 12; step++) {
      final mid = 0.5 * (low + high);
      final candidate = initialVal + (safeTarget - initialVal) * mid;
      if (trySolveConstrainedNumber(candidate)) {
        bestAlpha = mid;
        low = mid;
      } else {
        high = mid;
      }
    }

    if (bestAlpha > 1e-4) {
      final bestCandidate = initialVal + (safeTarget - initialVal) * bestAlpha;
      trySolveConstrainedNumber(bestCandidate);
      return true;
    }

    snapshot.restore(this);
    evaluateAll();
    return false;
  }

  /// General M x N Levenberg-Marquardt solver over [params] to drive [targets]
  /// residuals to zero.
  void _solveResiduals({
    required List<_ResidualTarget> targets,
    required List<SceneObject> params,
    required int maxIterations,
    required double tolerance,
    required double damping,
  }) {
    if (targets.isEmpty || params.isEmpty) return;

    final paramDescriptors = <_ParamRef>[];
    for (final p in params) {
      if (p is PointObject) {
        paramDescriptors.add(_ParamRef(p, _ParamType.pointX));
        paramDescriptors.add(_ParamRef(p, _ParamType.pointY));
      } else if (p is NumberObject) {
        paramDescriptors.add(_ParamRef(p, _ParamType.numberValue));
      }
    }
    if (paramDescriptors.isEmpty) return;

    const double delta = 1e-5;
    final int n = paramDescriptors.length;

    for (int iter = 0; iter < maxIterations; iter++) {
      evaluateAll();

      final residuals = <double>[];
      for (final t in targets) {
        t.appendResiduals(residuals);
      }
      final int m = residuals.length;
      if (m == 0) break;

      double errorSq = 0.0;
      for (int i = 0; i < m; i++) {
        errorSq += residuals[i] * residuals[i];
      }
      if (errorSq < tolerance * tolerance) {
        break;
      }

      // Compute M x N Jacobian matrix J (stored column-major: jCols[j][i])
      final jCols = List<List<double>>.generate(
        n,
        (_) => List<double>.filled(m, 0.0),
      );

      for (int j = 0; j < n; j++) {
        final ref = paramDescriptors[j];
        final originalVal = ref.get();
        ref.set(originalVal + delta);
        evaluateAll();

        final pertResiduals = <double>[];
        for (final t in targets) {
          t.appendResiduals(pertResiduals);
        }

        for (int i = 0; i < m; i++) {
          jCols[j][i] = (residuals[i] - pertResiduals[i]) / delta;
        }

        ref.set(originalVal);
      }

      evaluateAll();

      // Form N x N damped normal equations: (J^T J + lambda I_N) step = J^T e
      final aMat = List<List<double>>.generate(
        n,
        (r) => List<double>.filled(n, 0.0),
      );
      final rhs = List<double>.filled(n, 0.0);

      for (int r = 0; r < n; r++) {
        aMat[r][r] = damping;
        final colR = jCols[r];
        double bVal = 0.0;
        for (int i = 0; i < m; i++) {
          bVal += colR[i] * residuals[i];
        }
        rhs[r] = bVal;

        for (int c = r; c < n; c++) {
          final colC = jCols[c];
          double sum = 0.0;
          for (int i = 0; i < m; i++) {
            sum += colR[i] * colC[i];
          }
          aMat[r][c] += sum;
          if (c != r) {
            aMat[c][r] += sum;
          }
        }
      }

      final step = _solveLinearSystem(aMat, rhs);
      if (step == null) break;

      double maxStep = 0.0;
      for (int j = 0; j < n; j++) {
        final absStep = step[j].abs();
        if (absStep > maxStep) maxStep = absStep;
      }
      final double scale = maxStep > 0.25 ? (0.25 / maxStep) : 1.0;

      for (int j = 0; j < n; j++) {
        final ref = paramDescriptors[j];
        ref.set(ref.get() + step[j] * scale);
      }

      for (final p in params) {
        if (p is PointObject) {
          if (p.point.magnitudeSquared >= 1.0) {
            p.point = p.point.normalized().scale(0.9999);
          }
        } else if (p is NumberObject) {
          p.value = p.value.clamp(p.min, p.max);
        }
      }
    }

    evaluateAll();
  }

  List<double>? _solveLinearSystem(List<List<double>> a, List<double> b) {
    final int n = b.length;
    for (int k = 0; k < n; k++) {
      int pivot = k;
      double maxVal = a[k][k].abs();
      for (int i = k + 1; i < n; i++) {
        final v = a[i][k].abs();
        if (v > maxVal) {
          maxVal = v;
          pivot = i;
        }
      }
      if (maxVal < 1e-15) return null;

      if (pivot != k) {
        final tmpRow = a[k];
        a[k] = a[pivot];
        a[pivot] = tmpRow;
        final tmpB = b[k];
        b[k] = b[pivot];
        b[pivot] = tmpB;
      }

      final pivotVal = a[k][k];
      for (int i = k + 1; i < n; i++) {
        final factor = a[i][k] / pivotVal;
        b[i] -= factor * b[k];
        for (int j = k; j < n; j++) {
          a[i][j] -= factor * a[k][j];
        }
      }
    }

    final x = List<double>.filled(n, 0.0);
    for (int i = n - 1; i >= 0; i--) {
      double sum = b[i];
      for (int j = i + 1; j < n; j++) {
        sum -= a[i][j] * x[j];
      }
      x[i] = sum / a[i][i];
    }
    return x;
  }

  Map<String, dynamic> toJson() => {
    'objects': _objects.values.map((o) => o.toJson()).toList(),
    'constraints': _constraints.values.map((c) => c.toJson()).toList(),
  };

  factory ConstraintGraph.fromJson(Map<String, dynamic> json) {
    final graph = ConstraintGraph();

    if (json.containsKey('objects')) {
      final list = json['objects'] as List<dynamic>;
      for (final item in list) {
        final obj = parseSceneObject(item as Map<String, dynamic>);
        graph.addObject(obj);
      }
    }

    if (json.containsKey('constraints')) {
      final list = json['constraints'] as List<dynamic>;
      for (final item in list) {
        final cMap = item as Map<String, dynamic>;
        final c = parseConstraint(cMap);
        if (c != null) {
          graph.addConstraint(c);
        }
      }
    }

    graph.evaluateAll();
    return graph;
  }
}

enum _ParamType { pointX, pointY, numberValue }

class _ParamRef {
  final SceneObject object;
  final _ParamType type;

  _ParamRef(this.object, this.type);

  double get() {
    switch (type) {
      case _ParamType.pointX:
        return (object as PointObject).point.x;
      case _ParamType.pointY:
        return (object as PointObject).point.y;
      case _ParamType.numberValue:
        return (object as NumberObject).value;
    }
  }

  void set(double val) {
    switch (type) {
      case _ParamType.pointX:
        final pt = (object as PointObject).point;
        (object as PointObject).point = HyperbolicPoint(val, pt.y);
        break;
      case _ParamType.pointY:
        final pt = (object as PointObject).point;
        (object as PointObject).point = HyperbolicPoint(pt.x, val);
        break;
      case _ParamType.numberValue:
        (object as NumberObject).value = val;
        break;
    }
  }
}

class _GraphSnapshot {
  final Map<String, HyperbolicPoint> _points = {};
  final Map<String, bool> _visibilities = {};
  final Map<String, double> _numbers = {};

  _GraphSnapshot._();

  factory _GraphSnapshot.capture(ConstraintGraph graph) {
    final snap = _GraphSnapshot._();
    for (final obj in graph._objects.values) {
      snap._visibilities[obj.id] = obj.visible;
      if (obj is PointObject) {
        snap._points[obj.id] = obj.point;
      } else if (obj is NumberObject) {
        snap._numbers[obj.id] = obj.value;
      }
    }
    return snap;
  }

  void restore(ConstraintGraph graph) {
    for (final obj in graph._objects.values) {
      final vis = _visibilities[obj.id];
      if (vis != null) obj.visible = vis;
      if (obj is PointObject) {
        final pt = _points[obj.id];
        if (pt != null) obj.point = pt;
      } else if (obj is NumberObject) {
        final val = _numbers[obj.id];
        if (val != null) obj.value = val;
      }
    }
  }
}

abstract class _ResidualTarget {
  String get objectId;
  double get weight;
  void appendResiduals(List<double> out);
  double maxAbsError();
  _ResidualTarget withWeight(double newWeight);
}

class _PointResidualTarget extends _ResidualTarget {
  final PointObject object;
  final HyperbolicPoint target;
  @override
  final double weight;

  _PointResidualTarget(this.object, this.target, {this.weight = 1.0});

  @override
  String get objectId => object.id;

  @override
  void appendResiduals(List<double> out) {
    out.add(weight * (target.x - object.point.x));
    out.add(weight * (target.y - object.point.y));
  }

  @override
  double maxAbsError() {
    return (target - object.point).magnitude;
  }

  @override
  _ResidualTarget withWeight(double newWeight) =>
      _PointResidualTarget(object, target, weight: newWeight);
}

class _NumberResidualTarget extends _ResidualTarget {
  final NumberObject object;
  final double target;
  @override
  final double weight;

  _NumberResidualTarget(this.object, this.target, {this.weight = 1.0});

  @override
  String get objectId => object.id;

  @override
  void appendResiduals(List<double> out) {
    out.add(weight * (target - object.value));
  }

  @override
  double maxAbsError() {
    return (target - object.value).abs();
  }

  @override
  _ResidualTarget withWeight(double newWeight) =>
      _NumberResidualTarget(object, target, weight: newWeight);
}

class _CircleResidualTarget extends _ResidualTarget {
  final CircleObject object;
  final HyperbolicPoint targetCenter;
  final double targetRadius;
  @override
  final double weight;

  _CircleResidualTarget(
    this.object,
    this.targetCenter,
    this.targetRadius, {
    this.weight = 1.0,
  });

  @override
  String get objectId => object.id;

  @override
  void appendResiduals(List<double> out) {
    final circ = object.circle;
    if (circ == null) {
      out.add(0.0);
      out.add(0.0);
      out.add(0.0);
      return;
    }
    out.add(weight * (targetCenter.x - circ.hyperbolicCenter.x));
    out.add(weight * (targetCenter.y - circ.hyperbolicCenter.y));
    out.add(weight * (targetRadius - circ.hyperbolicRadius));
  }

  @override
  double maxAbsError() {
    final circ = object.circle;
    if (circ == null) return 0.0;
    return math.max(
      (targetCenter - circ.hyperbolicCenter).magnitude,
      (targetRadius - circ.hyperbolicRadius).abs(),
    );
  }

  @override
  _ResidualTarget withWeight(double newWeight) => _CircleResidualTarget(
    object,
    targetCenter,
    targetRadius,
    weight: newWeight,
  );
}

class _LineResidualTarget extends _ResidualTarget {
  final LineObject object;
  final HyperbolicPoint targetP1;
  final HyperbolicPoint targetP2;
  @override
  final double weight;

  _LineResidualTarget(
    this.object,
    this.targetP1,
    this.targetP2, {
    this.weight = 1.0,
  });

  @override
  String get objectId => object.id;

  @override
  void appendResiduals(List<double> out) {
    final p1 = object.p1;
    final p2 = object.p2;
    if (p1 == null || p2 == null) {
      out.add(0.0);
      out.add(0.0);
      out.add(0.0);
      out.add(0.0);
      return;
    }
    out.add(weight * (targetP1.x - p1.x));
    out.add(weight * (targetP1.y - p1.y));
    out.add(weight * (targetP2.x - p2.x));
    out.add(weight * (targetP2.y - p2.y));
  }

  @override
  double maxAbsError() {
    final p1 = object.p1;
    final p2 = object.p2;
    if (p1 == null || p2 == null) return 0.0;
    return math.max((targetP1 - p1).magnitude, (targetP2 - p2).magnitude);
  }

  @override
  _ResidualTarget withWeight(double newWeight) =>
      _LineResidualTarget(object, targetP1, targetP2, weight: newWeight);
}

/// Parses a [Constraint] from JSON.
Constraint? parseConstraint(Map<String, dynamic> json) {
  final type = json['type'] as String?;
  switch (type) {
    case 'freePoint':
      return FreePointConstraint.fromJson(json);
    case 'pointOnLine':
      return PointOnLineConstraint.fromJson(json);
    case 'pointOnCircle':
      return PointOnCircleConstraint.fromJson(json);
    case 'midpoint':
      return MidpointConstraint.fromJson(json);
    case 'equilateralPoint':
      return EquilateralPointConstraint.fromJson(json);
    case 'lineThroughPoints':
      return LineThroughPointsConstraint.fromJson(json);
    case 'angleLine':
      return AngleLineConstraint.fromJson(json);
    case 'perpendicularLine':
      return PerpendicularLineConstraint.fromJson(json);
    case 'perpendicularBisector':
      return PerpendicularBisectorConstraint.fromJson(json);
    case 'angleBisector':
      return AngleBisectorConstraint.fromJson(json);
    case 'circleCenterPoint':
      return CircleCenterPointConstraint.fromJson(json);
    case 'circleCenterRadius':
      return CircleCenterRadiusConstraint.fromJson(json);
    case 'compassCircle':
      return CompassCircleConstraint.fromJson(json);
    case 'intersection':
      return IntersectionConstraint.fromJson(json);
    case 'distanceMeasurement':
      return DistanceMeasurementConstraint.fromJson(json);
    case 'angleMeasurement':
      return AngleMeasurementConstraint.fromJson(json);
    case 'coordinateMeasurement':
      return CoordinateMeasurementConstraint.fromJson(json);
    default:
      return null;
  }
}
