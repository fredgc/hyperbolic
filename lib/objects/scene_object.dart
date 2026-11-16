import 'package:flutter/material.dart';

/// Supported types of scene objects in hyperbolic geometry diagrams.
enum ObjectType {
  point('point', 'Point'),
  line('line', 'Line'),
  circle('circle', 'Circle'),
  number('number', 'Number');

  final String jsonKey;
  final String label;

  const ObjectType(this.jsonKey, this.label);

  static ObjectType fromJson(String key) {
    for (final t in values) {
      if (t.jsonKey == key) return t;
    }
    throw ArgumentError('Unknown ObjectType json key: $key');
  }
}

/// Abstract base class for all geometric and numeric objects in the scene.
abstract class SceneObject {
  final String id;
  String name;
  int color;
  bool visible;
  bool locked;

  /// ID of the constraint that generates or governs this object.
  /// Null if this object is not attached to any constraint.
  String? constraintId;

  SceneObject({
    required this.id,
    required this.name,
    this.color = 0xFF000000,
    this.visible = true,
    this.locked = false,
    this.constraintId,
  });

  ObjectType get type;

  /// Whether this object is an ancestor input that can be freely edited.
  bool get isFree => constraintId == null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.jsonKey,
    'name': name,
    'color': color,
    'visible': visible,
    'locked': locked,
    if (constraintId != null) 'constraintId': constraintId,
  };

  void copyBasePropertiesFrom(SceneObject other) {
    name = other.name;
    color = other.color;
    visible = other.visible;
    locked = other.locked;
    constraintId = other.constraintId;
  }

  SceneObject clone();
}
