import 'scene_object.dart';

/// Semantic unit or interpretation of a numeric parameter.
enum NumberUnit {
  scalar('scalar', 'Scalar'),
  distance('distance', 'Hyperbolic Distance'),
  angleRadians('rad', 'Angle (rad)'),
  angleDegrees('deg', 'Angle (deg)'),
  coordinate('coord', 'Coordinate');

  final String jsonKey;
  final String label;

  const NumberUnit(this.jsonKey, this.label);

  static NumberUnit fromJson(String key) {
    for (final u in values) {
      if (u.jsonKey == key) return u;
    }
    return NumberUnit.scalar;
  }
}

/// A numeric parameter, distance, angle, or coordinate value.
class NumberObject extends SceneObject {
  double value;
  double min;
  double max;
  NumberUnit unit;

  NumberObject({
    required super.id,
    required super.name,
    this.value = 1.0,
    this.min = 0.0,
    this.max = 10.0,
    this.unit = NumberUnit.scalar,
    super.color = 0xFFFB8C00, // Orange
    super.visible = true,
    super.locked = false,
    super.constraintId,
  });

  @override
  ObjectType get type => ObjectType.number;

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['value'] = value;
    map['min'] = min;
    map['max'] = max;
    map['unit'] = unit.jsonKey;
    return map;
  }

  factory NumberObject.fromJson(Map<String, dynamic> json) {
    return NumberObject(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'n',
      value: (json['value'] as num?)?.toDouble() ?? 1.0,
      min: (json['min'] as num?)?.toDouble() ?? 0.0,
      max: (json['max'] as num?)?.toDouble() ?? 10.0,
      unit: NumberUnit.fromJson(json['unit'] as String? ?? 'scalar'),
      color: (json['color'] as num?)?.toInt() ?? 0xFFFB8C00,
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      constraintId: json['constraintId'] as String?,
    );
  }

  @override
  NumberObject clone() {
    return NumberObject(
      id: id,
      name: name,
      value: value,
      min: min,
      max: max,
      unit: unit,
      color: color,
      visible: visible,
      locked: locked,
      constraintId: constraintId,
    );
  }

  @override
  String toString() => 'NumberObject($name: $value, locked: $locked)';
}
