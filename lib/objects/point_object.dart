import '../transform.dart';
import 'scene_object.dart';

/// A point in the Poincaré disk (z in D, |z| < 1).
class PointObject extends SceneObject {
  HyperbolicPoint point;

  PointObject({
    required super.id,
    required super.name,
    this.point = const HyperbolicPoint.origin(),
    super.color = 0xFF5C6BC0, // Indigo accent
    super.visible = true,
    super.locked = false,
    super.constraintId,
  });

  @override
  ObjectType get type => ObjectType.point;

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['point'] = point.toJson();
    return map;
  }

  factory PointObject.fromJson(Map<String, dynamic> json) {
    return PointObject(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'P',
      point: json['point'] != null
          ? HyperbolicPoint.fromJson(json['point'] as Map<String, dynamic>)
          : const HyperbolicPoint.origin(),
      color: (json['color'] as num?)?.toInt() ?? 0xFF5C6BC0,
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      constraintId: json['constraintId'] as String?,
    );
  }

  @override
  PointObject clone() {
    return PointObject(
      id: id,
      name: name,
      point: point,
      color: color,
      visible: visible,
      locked: locked,
      constraintId: constraintId,
    );
  }

  @override
  String toString() => 'PointObject($name: $point, locked: $locked)';
}
