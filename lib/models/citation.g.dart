// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'citation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Citation _$CitationFromJson(Map<String, dynamic> json) => _Citation(
      url: json['url'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$CitationToJson(_Citation instance) => <String, dynamic>{
      'url': instance.url,
      'title': instance.title,
      'description': instance.description,
    };
