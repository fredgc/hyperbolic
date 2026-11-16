import 'circle_object.dart';
import 'line_object.dart';
import 'number_object.dart';
import 'point_object.dart';
import 'scene_object.dart';

export 'circle_object.dart';
export 'line_object.dart';
export 'number_object.dart';
export 'point_object.dart';
export 'scene_object.dart';

/// Parses a [SceneObject] from its JSON representation.
SceneObject parseSceneObject(Map<String, dynamic> json) {
  final typeKey = json['type'] as String;
  final type = ObjectType.fromJson(typeKey);
  switch (type) {
    case ObjectType.point:
      return PointObject.fromJson(json);
    case ObjectType.line:
      return LineObject.fromJson(json);
    case ObjectType.circle:
      return CircleObject.fromJson(json);
    case ObjectType.number:
      return NumberObject.fromJson(json);
  }
}
