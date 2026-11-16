import '../objects/objects.dart';
import '../transform.dart';
import 'constraint.dart';

/// A hyperbolic circle defined by a center point and a point on the circle.
class CircleCenterPointConstraint extends Constraint {
  CircleCenterPointConstraint({
    required super.id,
    required String centerId,
    required String pointOnCircleId,
    required String circleId,
  }) : super(inputIds: [centerId, pointOnCircleId], outputIds: [circleId]);

  @override
  String get type => 'circleCenterPoint';

  String get centerId => inputIds[0];
  String get pointOnCircleId => inputIds[1];
  String get circleId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final centerObj = lookup.getPoint(centerId);
    final ptObj = lookup.getPoint(pointOnCircleId);
    final circleObj = lookup.getCircle(circleId);
    if (centerObj == null || ptObj == null || circleObj == null) return;

    if (centerObj.point == ptObj.point) return;

    circleObj.circle = HyperbolicCircle.fromPoints(
      centerObj.point,
      ptObj.point,
    );
  }

  factory CircleCenterPointConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return CircleCenterPointConstraint(
      id: json['id'] as String,
      centerId: inputs[0],
      pointOnCircleId: inputs[1],
      circleId: outputs[0],
    );
  }

  @override
  CircleCenterPointConstraint clone() => CircleCenterPointConstraint(
    id: id,
    centerId: centerId,
    pointOnCircleId: pointOnCircleId,
    circleId: circleId,
  );
}

/// A hyperbolic circle defined by a center point and a radius Number.
class CircleCenterRadiusConstraint extends Constraint {
  CircleCenterRadiusConstraint({
    required super.id,
    required String centerId,
    required String radiusNumberId,
    required String circleId,
  }) : super(inputIds: [centerId, radiusNumberId], outputIds: [circleId]);

  @override
  String get type => 'circleCenterRadius';

  String get centerId => inputIds[0];
  String get radiusNumberId => inputIds[1];
  String get circleId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final centerObj = lookup.getPoint(centerId);
    final radiusNum = lookup.getNumber(radiusNumberId);
    final circleObj = lookup.getCircle(circleId);
    if (centerObj == null || radiusNum == null || circleObj == null) return;

    final double rho = radiusNum.value;
    if (rho <= 0.0) return;

    circleObj.circle = HyperbolicCircle(
      hyperbolicCenter: centerObj.point,
      hyperbolicRadius: rho,
    );
  }

  factory CircleCenterRadiusConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return CircleCenterRadiusConstraint(
      id: json['id'] as String,
      centerId: inputs[0],
      radiusNumberId: inputs[1],
      circleId: outputs[0],
    );
  }

  @override
  CircleCenterRadiusConstraint clone() => CircleCenterRadiusConstraint(
    id: id,
    centerId: centerId,
    radiusNumberId: radiusNumberId,
    circleId: circleId,
  );
}

/// A hyperbolic circle whose radius is dynamically equal to the hyperbolic
/// distance between two points [p1Id] and [p2Id] (compass distance transfer).
class CompassCircleConstraint extends Constraint {
  CompassCircleConstraint({
    required super.id,
    required String centerId,
    required String p1Id,
    required String p2Id,
    required String circleId,
  }) : super(inputIds: [centerId, p1Id, p2Id], outputIds: [circleId]);

  @override
  String get type => 'compassCircle';

  String get centerId => inputIds[0];
  String get p1Id => inputIds[1];
  String get p2Id => inputIds[2];
  String get circleId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final centerObj = lookup.getPoint(centerId);
    final p1Obj = lookup.getPoint(p1Id);
    final p2Obj = lookup.getPoint(p2Id);
    final circleObj = lookup.getCircle(circleId);
    if (centerObj == null ||
        p1Obj == null ||
        p2Obj == null ||
        circleObj == null) {
      return;
    }

    final double rho = p1Obj.point.hyperbolicDistance(p2Obj.point);
    if (rho <= 0.0) return;

    circleObj.circle = HyperbolicCircle(
      hyperbolicCenter: centerObj.point,
      hyperbolicRadius: rho,
    );
  }

  factory CompassCircleConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return CompassCircleConstraint(
      id: json['id'] as String,
      centerId: inputs[0],
      p1Id: inputs[1],
      p2Id: inputs[2],
      circleId: outputs[0],
    );
  }

  @override
  CompassCircleConstraint clone() => CompassCircleConstraint(
    id: id,
    centerId: centerId,
    p1Id: p1Id,
    p2Id: p2Id,
    circleId: circleId,
  );
}
