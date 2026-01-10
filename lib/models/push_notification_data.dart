import 'package:json_annotation/json_annotation.dart';

part 'push_notification_data.g.dart';

/// Model for push notification data payload
@JsonSerializable()
class PushNotificationData {
  final String? title;
  final String? body;
  final Map<String, dynamic>? data;

  PushNotificationData({
    this.title,
    this.body,
    this.data,
  });

  factory PushNotificationData.fromJson(Map<String, dynamic> json) =>
      _$PushNotificationDataFromJson(json);

  Map<String, dynamic> toJson() => _$PushNotificationDataToJson(this);

  /// Extract notification type from data payload
  String? get type => data?['type'] as String?;

  /// Extract message ID from data payload
  String? get messageId => data?['messageId'] as String?;

  /// Extract coach ID from data payload
  String? get coachId => data?['coachId'] as String?;

  /// Extract any custom data value
  T? getDataValue<T>(String key) => data?[key] as T?;
}

