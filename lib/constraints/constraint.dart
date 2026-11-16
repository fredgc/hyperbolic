import '../objects/objects.dart';

/// Lookup interface allowing constraints to read inputs and write outputs.
abstract class ConstraintLookup {
  SceneObject? getObject(String id);
  PointObject? getPoint(String id) => getObject(id) as PointObject?;
  LineObject? getLine(String id) => getObject(id) as LineObject?;
  CircleObject? getCircle(String id) => getObject(id) as CircleObject?;
  NumberObject? getNumber(String id) => getObject(id) as NumberObject?;
}

/// Abstract base class for all constraint nodes in the bipartite graph.
abstract class Constraint {
  final String id;
  final List<String> inputIds;
  final List<String> outputIds;

  Constraint({
    required this.id,
    required List<String> inputIds,
    required List<String> outputIds,
  }) : inputIds = List.unmodifiable(inputIds),
       outputIds = List.unmodifiable(outputIds);

  /// String identifier for serialization (e.g. 'lineThroughPoints').
  String get type;

  /// Re-evaluates this constraint, updating output object(s) from input(s).
  void evaluate(ConstraintLookup lookup);

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'inputIds': inputIds,
    'outputIds': outputIds,
  };

  Constraint clone();
}
