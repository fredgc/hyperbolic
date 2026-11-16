import 'dart:convert';
import '../constraints/constraints.dart';
import '../objects/objects.dart';
import '../transform.dart';

class SceneData {
  String title = 'Untitled Drawing';
  String description = '';
  double zoom = 1.0;
  bool isLegacy = false;

  final CoordinateTransform transform = CoordinateTransform();
  final ConstraintGraph graph = ConstraintGraph();

  List<SceneObject> get objects => graph.objects;
  List<Constraint> get constraints => graph.constraints;

  List<dynamic> get drawables => objects;

  SceneData();

  factory SceneData.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    final scene = SceneData();
    scene.title = json['title'] as String? ?? 'Untitled Drawing';
    scene.description = json['description'] as String? ?? '';
    scene.zoom = (json['zoom'] as num?)?.toDouble() ?? 1.0;

    if (json.containsKey('transform')) {
      scene.transform.loadFromJson(json['transform'] as Map<String, dynamic>);
    } else {
      scene.transform.zoom = scene.zoom;
    }

    if (json.containsKey('objects') || json.containsKey('constraints')) {
      final loadedGraph = ConstraintGraph.fromJson(json);
      for (final obj in loadedGraph.objects) {
        scene.graph.addObject(obj);
      }
      for (final c in loadedGraph.constraints) {
        scene.graph.addConstraint(c);
      }
      scene.graph.evaluateAll();
    }

    return scene;
  }

  Map<String, dynamic> toJson() {
    final map = graph.toJson();
    map['title'] = title;
    map['description'] = description;
    map['zoom'] = zoom;
    map['transform'] = transform.toJson();
    return map;
  }

  void clear() {
    graph.clear();
  }

  void dispose() {
    graph.clear();
  }
}
