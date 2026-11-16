import '../objects/objects.dart';
import '../transform.dart';
import 'constraint.dart';

/// Computes the hyperbolic distance between two points into a Number object.
class DistanceMeasurementConstraint extends Constraint {
  DistanceMeasurementConstraint({
    required super.id,
    required String p1Id,
    required String p2Id,
    required String numberId,
  }) : super(inputIds: [p1Id, p2Id], outputIds: [numberId]);

  @override
  String get type => 'distanceMeasurement';

  String get p1Id => inputIds[0];
  String get p2Id => inputIds[1];
  String get numberId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final p1 = lookup.getPoint(p1Id);
    final p2 = lookup.getPoint(p2Id);
    final numObj = lookup.getNumber(numberId);
    if (p1 == null || p2 == null || numObj == null) return;

    numObj.value = p1.point.hyperbolicDistance(p2.point);
  }

  factory DistanceMeasurementConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return DistanceMeasurementConstraint(
      id: json['id'] as String,
      p1Id: inputs[0],
      p2Id: inputs[1],
      numberId: outputs[0],
    );
  }

  @override
  DistanceMeasurementConstraint clone() => DistanceMeasurementConstraint(
    id: id,
    p1Id: p1Id,
    p2Id: p2Id,
    numberId: numberId,
  );
}

/// Computes the hyperbolic angle at vertex [vertexId] between [p1Id] and [p2Id].
class AngleMeasurementConstraint extends Constraint {
  AngleMeasurementConstraint({
    required super.id,
    required String p1Id,
    required String vertexId,
    required String p2Id,
    required String numberId,
  }) : super(inputIds: [p1Id, vertexId, p2Id], outputIds: [numberId]);

  @override
  String get type => 'angleMeasurement';

  String get p1Id => inputIds[0];
  String get vertexId => inputIds[1];
  String get p2Id => inputIds[2];
  String get numberId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final p1 = lookup.getPoint(p1Id);
    final v = lookup.getPoint(vertexId);
    final p2 = lookup.getPoint(p2Id);
    final numObj = lookup.getNumber(numberId);
    if (p1 == null || v == null || p2 == null || numObj == null) return;

    numObj.value = angleBetween(p1.point, v.point, p2.point);
  }

  factory AngleMeasurementConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return AngleMeasurementConstraint(
      id: json['id'] as String,
      p1Id: inputs[0],
      vertexId: inputs[1],
      p2Id: inputs[2],
      numberId: outputs[0],
    );
  }

  @override
  AngleMeasurementConstraint clone() => AngleMeasurementConstraint(
    id: id,
    p1Id: p1Id,
    vertexId: vertexId,
    p2Id: p2Id,
    numberId: numberId,
  );
}

/// Extracts a coordinate (x, y, r, theta) of a point into a Number object.
class CoordinateMeasurementConstraint extends Constraint {
  final String coordinate; // 'x', 'y', 'r', 'theta'

  CoordinateMeasurementConstraint({
    required super.id,
    required String pointId,
    required String numberId,
    this.coordinate = 'x',
  }) : super(inputIds: [pointId], outputIds: [numberId]);

  @override
  String get type => 'coordinateMeasurement';

  String get pointId => inputIds[0];
  String get numberId => outputIds[0];

  @override
  void evaluate(ConstraintLookup lookup) {
    final pt = lookup.getPoint(pointId);
    final numObj = lookup.getNumber(numberId);
    if (pt == null || numObj == null) return;

    switch (coordinate) {
      case 'x':
        numObj.value = pt.point.x;
        break;
      case 'y':
        numObj.value = pt.point.y;
        break;
      case 'r':
        numObj.value = pt.point.magnitude;
        break;
      case 'theta':
        numObj.value = pt.point.arg;
        break;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['coordinate'] = coordinate;
    return map;
  }

  factory CoordinateMeasurementConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return CoordinateMeasurementConstraint(
      id: json['id'] as String,
      pointId: inputs[0],
      numberId: outputs[0],
      coordinate: json['coordinate'] as String? ?? 'x',
    );
  }

  @override
  CoordinateMeasurementConstraint clone() => CoordinateMeasurementConstraint(
    id: id,
    pointId: pointId,
    numberId: numberId,
    coordinate: coordinate,
  );
}
