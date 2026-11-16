import '../transform.dart';
import 'scene_object.dart';

/// Supported geometric styles of a hyperbolic geodesic.
enum LineStyle {
  fullLine('line', 'Full Geodesic'),
  segment('segment', 'Segment'),
  ray('ray', 'Ray');

  final String jsonKey;
  final String label;

  const LineStyle(this.jsonKey, this.label);

  static LineStyle fromJson(String key) {
    for (final s in values) {
      if (s.jsonKey == key) return s;
    }
    return LineStyle.fullLine;
  }
}

/// A hyperbolic geodesic, segment, or ray inside the Poincaré disk.
class LineObject extends SceneObject {
  LineStyle lineStyle;
  double strokeWidth;

  /// Computed geodesic geometry.
  HyperbolicLine? line;

  /// Endpoints when [lineStyle] is [LineStyle.segment] or [LineStyle.ray].
  HyperbolicPoint? p1;
  HyperbolicPoint? p2;

  LineObject({
    required super.id,
    required super.name,
    this.lineStyle = LineStyle.fullLine,
    this.strokeWidth = 2.0,
    this.line,
    this.p1,
    this.p2,
    super.color = 0xFF1E88E5, // Blue
    super.visible = true,
    super.locked = false,
    super.constraintId,
  });

  @override
  ObjectType get type => ObjectType.line;

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['lineStyle'] = lineStyle.jsonKey;
    map['strokeWidth'] = strokeWidth;
    if (p1 != null) map['p1'] = p1!.toJson();
    if (p2 != null) map['p2'] = p2!.toJson();
    return map;
  }

  factory LineObject.fromJson(Map<String, dynamic> json) {
    return LineObject(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'L',
      lineStyle: LineStyle.fromJson(json['lineStyle'] as String? ?? 'line'),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      p1: json['p1'] != null
          ? HyperbolicPoint.fromJson(json['p1'] as Map<String, dynamic>)
          : null,
      p2: json['p2'] != null
          ? HyperbolicPoint.fromJson(json['p2'] as Map<String, dynamic>)
          : null,
      color: (json['color'] as num?)?.toInt() ?? 0xFF1E88E5,
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      constraintId: json['constraintId'] as String?,
    );
  }

  @override
  LineObject clone() {
    return LineObject(
      id: id,
      name: name,
      lineStyle: lineStyle,
      strokeWidth: strokeWidth,
      line: line,
      p1: p1,
      p2: p2,
      color: color,
      visible: visible,
      locked: locked,
      constraintId: constraintId,
    );
  }

  @override
  String toString() => 'LineObject($name: $lineStyle, locked: $locked)';
}
