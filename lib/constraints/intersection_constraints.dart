import '../objects/objects.dart';
import '../transform.dart';
import 'constraint.dart';

/// Intersection of two geometric objects (Line-Line, Line-Circle, Circle-Circle).
class IntersectionConstraint extends Constraint {
  final int index;

  IntersectionConstraint({
    required super.id,
    required String obj1Id,
    required String obj2Id,
    required String pointId,
    this.index = 0,
  }) : super(inputIds: [obj1Id, obj2Id], outputIds: [pointId]);

  @override
  String get type => 'intersection';

  String get obj1Id => inputIds[0];
  String get obj2Id => inputIds[1];
  String get pointId => outputIds[0];

  List<HyperbolicPoint> computeIntersections(ConstraintLookup lookup) {
    final obj1 = lookup.getObject(obj1Id);
    final obj2 = lookup.getObject(obj2Id);
    if (obj1 == null || obj2 == null) return const [];

    if (obj1 is LineObject && obj2 is LineObject) {
      if (obj1.line != null && obj2.line != null) {
        return intersectLineLine(obj1.line!, obj2.line!);
      }
    } else if (obj1 is LineObject && obj2 is CircleObject) {
      if (obj1.line != null && obj2.circle != null) {
        return intersectLineCircle(obj1.line!, obj2.circle!);
      }
    } else if (obj1 is CircleObject && obj2 is LineObject) {
      if (obj2.line != null && obj1.circle != null) {
        return intersectLineCircle(obj2.line!, obj1.circle!);
      }
    } else if (obj1 is CircleObject && obj2 is CircleObject) {
      if (obj1.circle != null && obj2.circle != null) {
        return intersectCircleCircle(obj1.circle!, obj2.circle!);
      }
    }
    return const [];
  }

  @override
  void evaluate(ConstraintLookup lookup) {
    final ptObj = lookup.getPoint(pointId);
    if (ptObj == null) return;

    final intersections = computeIntersections(lookup);
    if (intersections.isEmpty) {
      ptObj.visible = false;
      return;
    }

    ptObj.visible = true;
    if (index >= 0 && index < intersections.length) {
      ptObj.point = intersections[index];
    } else {
      ptObj.point = intersections.first;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['index'] = index;
    return map;
  }

  factory IntersectionConstraint.fromJson(Map<String, dynamic> json) {
    final inputs = List<String>.from(json['inputIds'] as List);
    final outputs = List<String>.from(json['outputIds'] as List);
    return IntersectionConstraint(
      id: json['id'] as String,
      obj1Id: inputs[0],
      obj2Id: inputs[1],
      pointId: outputs[0],
      index: (json['index'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  IntersectionConstraint clone() => IntersectionConstraint(
    id: id,
    obj1Id: obj1Id,
    obj2Id: obj2Id,
    pointId: pointId,
    index: index,
  );
}
