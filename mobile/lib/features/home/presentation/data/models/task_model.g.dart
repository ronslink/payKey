// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskImpl _$$TaskImplFromJson(Map<String, dynamic> json) => _$TaskImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  priority: json['priority'] as String,
  dueDate: DateTime.parse(json['dueDate'] as String),
  actionUrl: json['actionUrl'] as String?,
  status: json['status'] as String?,
  color: json['color'] as String?,
);

Map<String, dynamic> _$$TaskImplToJson(_$TaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'priority': instance.priority,
      'dueDate': instance.dueDate.toIso8601String(),
      'actionUrl': instance.actionUrl,
      'status': instance.status,
      'color': instance.color,
    };
