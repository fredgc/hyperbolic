import 'dart:math' as math;
import '../objects/objects.dart';
import '../transform.dart';
import 'constraint.dart';

/// A hyperbolic geodesic, segment, or ray through two distinct points.
class LineThroughPointsConstraint extends Constraint {
  LineThroughPointsConstraint({
    required super.id,
    required String p1Id,
    required String p2Id,
    required String lineId,
  }) : super(inputIds: [p1Id, p2Id], outputIds: [lineId]);

  @override
  String get type => 'lineThroughPoints';

  String get p1Id => inputIds[0];
  String get p2Id => inputIds[1];
  String get lineId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final p1Obj = lookup.getPoint(p1Id);
    final p2Obj = lookup.getPoint(p2Id);
    final lineObj = lookup.getLine(lineId);
    if (p1Obj == null || p2Obj == null || lineObj == null) return;

    if (p1Obj.point == p2Obj.point) {
      // Degenerate: cannot form line with identical points
      return;
    }

    lineObj.line = HyperbolicLine.fromPoints(p1Obj.point, p2Obj.point);
    lineObj.p1 = p1Obj.point;
    lineObj.p2 = p2Obj.point;
  }

  factory LineThroughPointsConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return LineThroughPointsConstraint(
      id: json['id'] as String,
      p1Id: inputs[0],
      p2Id: inputs[1],
      lineId: outputs[0],
    );
  }

  @override
  LineThroughPointsConstraint clone() => LineThroughPointsConstraint(
    id: id,
    p1Id: p1Id,
    p2Id: p2Id,
    lineId: lineId,
  );
}

/// A line through point [pointId] forming angle [angleNumberId] with [baseLineId].
class AngleLineConstraint extends Constraint {
  AngleLineConstraint({
    required super.id,
    required String baseLineId,
    required String pointId,
    required String angleNumberId,
    required String lineId,
  }) : super(
         inputIds: [baseLineId, pointId, angleNumberId],
         outputIds: [lineId],
       );

  @override
  String get type => 'angleLine';

  String get baseLineId => inputIds[0];
  String get pointId => inputIds[1];
  String get angleNumberId => inputIds[2];
  String get lineId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final baseLineObj = lookup.getLine(baseLineId);
    final ptObj = lookup.getPoint(pointId);
    final angleNum = lookup.getNumber(angleNumberId);
    final lineObj = lookup.getLine(lineId);
    if (baseLineObj == null ||
        ptObj == null ||
        angleNum == null ||
        lineObj == null)
      return;
    if (baseLineObj.line == null) return;

    final baseLine = baseLineObj.line!;
    final pt = ptObj.point;
    // Project point to baseline if needed to get tangent direction:
    final foot = baseLine.containsPoint(pt) ? pt : baseLine.projectPoint(pt);
    final baseTangent = baseLine.tangentAt(foot);
    final double baseAngle = math.atan2(baseTangent.y, baseTangent.x);

    final double targetAngle = baseAngle + angleNum.value;
    lineObj.line = HyperbolicLine.fromPointAndAngle(pt, targetAngle);
  }

  factory AngleLineConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return AngleLineConstraint(
      id: json['id'] as String,
      baseLineId: inputs[0],
      pointId: inputs[1],
      angleNumberId: inputs[2],
      lineId: outputs[0],
    );
  }

  @override
  AngleLineConstraint clone() => AngleLineConstraint(
    id: id,
    baseLineId: baseLineId,
    pointId: pointId,
    angleNumberId: angleNumberId,
    lineId: lineId,
  );
}

/// A geodesic line perpendicular to [baseLineId] passing through [pointId].
class PerpendicularLineConstraint extends Constraint {
  PerpendicularLineConstraint({
    required super.id,
    required String baseLineId,
    required String pointId,
    required String lineId,
  }) : super(inputIds: [baseLineId, pointId], outputIds: [lineId]);

  @override
  String get type => 'perpendicularLine';

  String get baseLineId => inputIds[0];
  String get pointId => inputIds[1];
  String get lineId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final baseLineObj = lookup.getLine(baseLineId);
    final ptObj = lookup.getPoint(pointId);
    final lineObj = lookup.getLine(lineId);
    if (baseLineObj == null || ptObj == null || lineObj == null) return;
    if (baseLineObj.line == null) return;

    lineObj.line = baseLineObj.line!.perpendicularAt(ptObj.point);
  }

  factory PerpendicularLineConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return PerpendicularLineConstraint(
      id: json['id'] as String,
      baseLineId: inputs[0],
      pointId: inputs[1],
      lineId: outputs[0],
    );
  }

  @override
  PerpendicularLineConstraint clone() => PerpendicularLineConstraint(
    id: id,
    baseLineId: baseLineId,
    pointId: pointId,
    lineId: lineId,
  );
}

/// A geodesic perpendicular bisector of the segment between [p1Id] and [p2Id].
class PerpendicularBisectorConstraint extends Constraint {
  PerpendicularBisectorConstraint({
    required super.id,
    required String p1Id,
    required String p2Id,
    required String lineId,
  }) : super(inputIds: [p1Id, p2Id], outputIds: [lineId]);

  @override
  String get type => 'perpendicularBisector';

  String get p1Id => inputIds[0];
  String get p2Id => inputIds[1];
  String get lineId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final p1Obj = lookup.getPoint(p1Id);
    final p2Obj = lookup.getPoint(p2Id);
    final lineObj = lookup.getLine(lineId);
    if (p1Obj == null || p2Obj == null || lineObj == null) return;
    if (p1Obj.point == p2Obj.point) return;

    final segment = HyperbolicSegment(p1Obj.point, p2Obj.point);
    final mid = segment.midpoint;
    lineObj.line = segment.line.perpendicularAt(mid);
  }

  factory PerpendicularBisectorConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return PerpendicularBisectorConstraint(
      id: json['id'] as String,
      p1Id: inputs[0],
      p2Id: inputs[1],
      lineId: outputs[0],
    );
  }

  @override
  PerpendicularBisectorConstraint clone() => PerpendicularBisectorConstraint(
    id: id,
    p1Id: p1Id,
    p2Id: p2Id,
    lineId: lineId,
  );
}

/// A geodesic line or ray bisecting the angle at vertex [vertexId] between [p1Id] and [p2Id].
class AngleBisectorConstraint extends Constraint {
  AngleBisectorConstraint({
    required super.id,
    required String p1Id,
    required String vertexId,
    required String p2Id,
    required String lineId,
  }) : super(inputIds: [p1Id, vertexId, p2Id], outputIds: [lineId]);

  @override
  String get type => 'angleBisector';

  String get p1Id => inputIds[0];
  String get vertexId => inputIds[1];
  String get p2Id => inputIds[2];
  String get lineId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final p1Obj = lookup.getPoint(p1Id);
    final vObj = lookup.getPoint(vertexId);
    final p2Obj = lookup.getPoint(p2Id);
    final lineObj = lookup.getLine(lineId);
    if (p1Obj == null || vObj == null || p2Obj == null || lineObj == null) {
      return;
    }
    if (p1Obj.point == vObj.point || p2Obj.point == vObj.point) return;

    final v = vObj.point;
    final m = MobiusTransform.translationOnly(v);
    final p1Prime = m.apply(p1Obj.point);
    final p2Prime = m.apply(p2Obj.point);
    if (p1Prime.magnitudeSquared < 1e-12 || p2Prime.magnitudeSquared < 1e-12) {
      return;
    }

    final double a1 = p1Prime.arg;
    double a2 = p2Prime.arg;
    double diff = a2 - a1;
    while (diff > math.pi) {
      diff -= 2 * math.pi;
    }
    while (diff < -math.pi) {
      diff += 2 * math.pi;
    }
    final double bisectAngle = a1 + diff / 2.0;
    final bisectDirAtOrigin = HyperbolicPoint(
      math.cos(bisectAngle) * 0.5,
      math.sin(bisectAngle) * 0.5,
    );
    final bisectPtInDisk = m.inverse(bisectDirAtOrigin);

    lineObj.line = HyperbolicLine.fromPoints(v, bisectPtInDisk);
    lineObj.p1 = v;
    lineObj.p2 = bisectPtInDisk;
  }

  factory AngleBisectorConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return AngleBisectorConstraint(
      id: json['id'] as String,
      p1Id: inputs[0],
      vertexId: inputs[1],
      p2Id: inputs[2],
      lineId: outputs[0],
    );
  }

  @override
  AngleBisectorConstraint clone() => AngleBisectorConstraint(
    id: id,
    p1Id: p1Id,
    vertexId: vertexId,
    p2Id: p2Id,
    lineId: lineId,
  );
}
