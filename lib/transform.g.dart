// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transform.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HyperbolicPoint _$HyperbolicPointFromJson(Map<String, dynamic> json) =>
    HyperbolicPoint(
      (json['x'] as num?)?.toDouble() ?? 0.0,
      (json['y'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$HyperbolicPointToJson(HyperbolicPoint instance) =>
    <String, dynamic>{'x': instance.x, 'y': instance.y};

MobiusTransform _$MobiusTransformFromJson(Map<String, dynamic> json) =>
    MobiusTransform(
      translation: json['translation'] == null
          ? const HyperbolicPoint.origin()
          : HyperbolicPoint.fromJson(
              json['translation'] as Map<String, dynamic>,
            ),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$MobiusTransformToJson(MobiusTransform instance) =>
    <String, dynamic>{
      'translation': instance.translation,
      'rotation': instance.rotation,
    };
