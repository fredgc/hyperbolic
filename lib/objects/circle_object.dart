import '../transform.dart';
import 'scene_object.dart';

/// A hyperbolic circle inside the Poincaré disk.
class CircleObject extends SceneObject {
  double strokeWidth;
  bool filled;

  /// Computed hyperbolic/Euclidean circle geometry.
  HyperbolicCircle? circle;

  CircleObject({
    required super.id,
    required super.name,
    this.strokeWidth = 2.0,
    this.filled = false,
    this.circle,
    super.color = 0xFF43A047, // Green
    super.visible = true,
    super.locked = false,
    super.constraintId,
  });

  @override
  ObjectType get type => ObjectType.circle;

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['strokeWidth'] = strokeWidth;
    map['filled'] = filled;
    if (circle != null) {
      map['center'] = circle!.hyperbolicCenter.toJson();
      map['radius'] = circle!.hyperbolicRadius;
    }
    return map;
  }

  factory CircleObject.fromJson(Map<String, dynamic> json) {
    HyperbolicCircle? circ;
    if (json.containsKey('center') && json.containsKey('radius')) {
      final center = HyperbolicPoint.fromJson(
        json['center'] as Map<String, dynamic>,
      );
      final radius = (json['radius'] as num).toDouble();
      circ = HyperbolicCircle(
        hyperbolicCenter: center,
        hyperbolicRadius: radius,
      );
    }

    return CircleObject(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'C',
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      filled: json['filled'] as bool? ?? false,
      circle: circ,
      color: (json['color'] as num?)?.toInt() ?? 0xFF43A047,
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      constraintId: json['constraintId'] as String?,
    );
  }

  @override
  CircleObject clone() {
    return CircleObject(
      id: id,
      name: name,
      strokeWidth: strokeWidth,
      filled: filled,
      circle: circle,
      color: color,
      visible: visible,
      locked: locked,
      constraintId: constraintId,
    );
  }

  @override
  String toString() => 'CircleObject($name: $circle, locked: $locked)';
}
