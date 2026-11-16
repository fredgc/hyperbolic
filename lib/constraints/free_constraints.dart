import 'dart:math' as math;
import '../objects/objects.dart';
import '../transform.dart';
import 'constraint.dart';

/// A free point constraint.
///
/// If [xNumberId] and [yNumberId] are provided, the point is driven by those two
/// numbers. Otherwise, the point is directly positioned by the user.
class FreePointConstraint extends Constraint {
  final String? xNumberId;
  final String? yNumberId;

  FreePointConstraint({
    required super.id,
    required String pointId,
    this.xNumberId,
    this.yNumberId,
  }) : super(
         inputIds: [
           if (xNumberId != null) xNumberId,
           if (yNumberId != null) yNumberId,
         ],
         outputIds: [pointId],
       );

  @override
  String get type => 'freePoint';

  String get pointId => outputIds.first;

  @override
  void evaluate(ConstraintLookup lookup) {
    final ptObj = lookup.getPoint(pointId);
    if (ptObj == null) return;

    if (xNumberId != null && yNumberId != null) {
      final xNum = lookup.getNumber(xNumberId!);
      final yNum = lookup.getNumber(yNumberId!);
      if (xNum != null && yNum != null) {
        ptObj.point = HyperbolicPoint(xNum.value, yNum.value);
      }
    }

    // Clamp point strictly inside unit disk:
    if (ptObj.point.magnitudeSquared >= 1.0) {
      final unit = ptObj.point.normalized();
      ptObj.point = unit.scale(0.9999);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    if (xNumberId != null) map['xNumberId'] = xNumberId;
    if (yNumberId != null) map['yNumberId'] = yNumberId;
    return map;
  }

  factory FreePointConstraint.fromJson(Map<String, dynamic> json) {
    final outputs = List<String>.from(json['outputIds'] as List);
    return FreePointConstraint(
      id: json['id'] as String,
      pointId: outputs.first,
      xNumberId: json['xNumberId'] as String?,
      yNumberId: json['yNumberId'] as String?,
    );
  }

  @override
  FreePointConstraint clone() => FreePointConstraint(
    id: id,
    pointId: pointId,
    xNumberId: xNumberId,
    yNumberId: yNumberId,
  );
}

/// A point constrained to lie on a hyperbolic line/segment.
///
/// If [lineId] is a full line, [paramNumberId] represents hyperbolic arc length
/// from the point on the line closest to the origin. If [lineId] is a segment,
/// [paramNumberId] represents the fractional distance in [0, 1].
class PointOnLineConstraint extends Constraint {
  PointOnLineConstraint({
    required super.id,
    required String lineId,
    required String paramNumberId,
    required String pointId,
  }) : super(inputIds: [lineId, paramNumberId], outputIds: [pointId]);

  @override
  String get type => 'pointOnLine';

  String get lineId => inputIds[0];
  String get paramNumberId => inputIds[1];
  String get pointId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final lineObj = lookup.getLine(lineId);
    final paramNum = lookup.getNumber(paramNumberId);
    final ptObj = lookup.getPoint(pointId);
    if (lineObj == null || paramNum == null || ptObj == null) return;
    if (lineObj.line == null) return;

    if (lineObj.lineStyle == LineStyle.segment &&
        lineObj.p1 != null &&
        lineObj.p2 != null) {
      final segment = HyperbolicSegment(lineObj.p1!, lineObj.p2!);
      ptObj.point = segment.pointAtFraction(paramNum.value);
    } else {
      // For a line, treat param.value as distance along line:
      final line = lineObj.line!;
      HyperbolicPoint pRef;
      if (line.isDiameter) {
        pRef = const HyperbolicPoint.origin();
      } else {
        final double d = line.euclideanCenter.magnitude;
        final double rClosest = d - line.euclideanRadius;
        pRef = line.euclideanCenter.normalized().scale(rClosest);
      }

      // Translate pRef to origin:
      final mobius = MobiusTransform.translationOnly(pRef);
      // Direction along line in transformed space:
      final normal = line.normalAt(pRef);
      final tangent = mobius
          .apply(pRef + HyperbolicPoint(-normal.y, normal.x).scale(0.01))
          .normalized();

      final double targetRho = paramNum.value;
      final double targetR = hyperbolicDistanceToRadius(targetRho.abs());
      final sign = targetRho >= 0 ? 1.0 : -1.0;
      final targetAtOrigin = tangent.scale(targetR * sign);

      ptObj.point = mobius.inverse(targetAtOrigin);
    }
  }

  factory PointOnLineConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return PointOnLineConstraint(
      id: json['id'] as String,
      lineId: inputs[0],
      paramNumberId: inputs[1],
      pointId: outputs[0],
    );
  }

  @override
  PointOnLineConstraint clone() => PointOnLineConstraint(
    id: id,
    lineId: lineId,
    paramNumberId: paramNumberId,
    pointId: pointId,
  );
}

/// A point constrained to lie on a hyperbolic circle at angle [angleNumberId].
class PointOnCircleConstraint extends Constraint {
  PointOnCircleConstraint({
    required super.id,
    required String circleId,
    required String angleNumberId,
    required String pointId,
  }) : super(inputIds: [circleId, angleNumberId], outputIds: [pointId]);

  @override
  String get type => 'pointOnCircle';

  String get circleId => inputIds[0];
  String get angleNumberId => inputIds[1];
  String get pointId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final circleObj = lookup.getCircle(circleId);
    final angleNum = lookup.getNumber(angleNumberId);
    final ptObj = lookup.getPoint(pointId);
    if (circleObj == null || angleNum == null || ptObj == null) return;
    if (circleObj.circle == null) return;

    ptObj.point = circleObj.circle!.pointAtAngle(angleNum.value);
  }

  factory PointOnCircleConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return PointOnCircleConstraint(
      id: json['id'] as String,
      circleId: inputs[0],
      angleNumberId: inputs[1],
      pointId: outputs[0],
    );
  }

  @override
  PointOnCircleConstraint clone() => PointOnCircleConstraint(
    id: id,
    circleId: circleId,
    angleNumberId: angleNumberId,
    pointId: pointId,
  );
}

/// A point constrained to be the hyperbolic midpoint of two points.
class MidpointConstraint extends Constraint {
  MidpointConstraint({
    required super.id,
    required String p1Id,
    required String p2Id,
    required String pointId,
  }) : super(inputIds: [p1Id, p2Id], outputIds: [pointId]);

  @override
  String get type => 'midpoint';

  String get p1Id => inputIds[0];
  String get p2Id => inputIds[1];
  String get pointId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final p1 = lookup.getPoint(p1Id);
    final p2 = lookup.getPoint(p2Id);
    final pt = lookup.getPoint(pointId);
    if (p1 == null || p2 == null || pt == null) return;

    if (p1.point == p2.point) {
      pt.point = p1.point;
      return;
    }

    pt.point = HyperbolicSegment(p1.point, p2.point).midpoint;
  }

  factory MidpointConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return MidpointConstraint(
      id: json['id'] as String,
      p1Id: inputs[0],
      p2Id: inputs[1],
      pointId: outputs[0],
    );
  }

  @override
  MidpointConstraint clone() =>
      MidpointConstraint(id: id, p1Id: p1Id, p2Id: p2Id, pointId: pointId);
}

/// A point constrained to form an equilateral triangle with [p1Id] and [p2Id].
class EquilateralPointConstraint extends Constraint {
  EquilateralPointConstraint({
    required super.id,
    required String p1Id,
    required String p2Id,
    required String pointId,
  }) : super(inputIds: [p1Id, p2Id], outputIds: [pointId]);

  @override
  String get type => 'equilateralPoint';

  String get p1Id => inputIds[0];
  String get p2Id => inputIds[1];
  String get pointId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final p1 = lookup.getPoint(p1Id);
    final p2 = lookup.getPoint(p2Id);
    final pt = lookup.getPoint(pointId);
    if (p1 == null || p2 == null || pt == null) return;
    if (p1.point == p2.point) return;

    final c1 = HyperbolicCircle.fromPoints(p1.point, p2.point);
    final c2 = HyperbolicCircle.fromPoints(p2.point, p1.point);
    final intersections = intersectCircleCircle(c1, c2);
    if (intersections.isEmpty) return;

    if (intersections.length == 1) {
      pt.point = intersections.first;
      return;
    }

    // Select the intersection that maintains positive (counterclockwise) orientation:
    final dx = p2.point.x - p1.point.x;
    final dy = p2.point.y - p1.point.y;
    final target = intersections.firstWhere(
      (p) => dx * (p.y - p1.point.y) - dy * (p.x - p1.point.x) > 0,
      orElse: () => intersections.first,
    );
    pt.point = target;
  }

  factory EquilateralPointConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return EquilateralPointConstraint(
      id: json['id'] as String,
      p1Id: inputs[0],
      p2Id: inputs[1],
      pointId: outputs[0],
    );
  }

  @override
  EquilateralPointConstraint clone() => EquilateralPointConstraint(
    id: id,
    p1Id: p1Id,
    p2Id: p2Id,
    pointId: pointId,
  );
}
