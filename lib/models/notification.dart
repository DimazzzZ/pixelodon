// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'account.dart';
import 'status.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

/// Converter for handling both string and integer values in JSON
class StringOrIntConverter implements JsonConverter<String?, dynamic> {
  const StringOrIntConverter();

  @override
  String? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is String) return json;
    if (json is int) return json.toString();
    if (json is double) return json.toInt().toString();
    return json.toString();
  }

  @override
  dynamic toJson(String? object) => object;
}

/// Converter for handling both boolean and string boolean values in JSON
class BoolConverter implements JsonConverter<bool, dynamic> {
  const BoolConverter();

  @override
  bool fromJson(dynamic json) {
    if (json == null) return false;
    if (json is bool) return json;
    if (json is String) {
      return json.toLowerCase() == 'true' || json == '1';
    }
    if (json is int) return json != 0;
    return false;
  }

  @override
  dynamic toJson(bool object) => object;
}

/// Represents a notification on Mastodon or Pixelfed
@freezed
class Notification with _$Notification {
  const factory Notification({
    /// The ID of the notification
    required String id,
    
    /// The type of the notification
    required NotificationType type,
    
    /// When the notification was created
    @JsonKey(name: 'created_at')
    required DateTime createdAt,
    
    /// The account that triggered the notification
    required Account account,
    
    /// The status associated with the notification (if applicable)
    Status? status,
    
    /// The ID of the status associated with the notification (if applicable)
    @JsonKey(name: 'status_id')
    @StringOrIntConverter()
    String? statusId,
    
    /// The ID of the report associated with the notification (if applicable)
    @JsonKey(name: 'report_id')
    @StringOrIntConverter()
    String? reportId,
    
    /// Whether the notification has been read
    @Default(false)
    @BoolConverter()
    bool read,
    
    /// The domain of the instance that sent the notification
    String? domain,
    
    /// Whether the notification is from a Pixelfed instance
    @Default(false) bool isPixelfed,
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
}

/// Type of notification
enum NotificationType {
  @JsonValue('follow')
  follow,
  
  @JsonValue('follow_request')
  followRequest,
  
  @JsonValue('mention')
  mention,
  
  @JsonValue('reblog')
  reblog,
  
  @JsonValue('favourite')
  favourite,
  
  @JsonValue('poll')
  poll,
  
  @JsonValue('status')
  status,
  
  @JsonValue('update')
  update,
  
  @JsonValue('admin.sign_up')
  adminSignUp,
  
  @JsonValue('admin.report')
  adminReport,
  
  // Pixelfed specific
  @JsonValue('comment')
  comment,
  
  @JsonValue('like')
  like,
  
  @JsonValue('share')
  share,
  
  @JsonValue('story.reaction')
  storyReaction,
  
  @JsonValue('story.mention')
  storyMention,
  
  @JsonValue('direct')
  direct,
  
  @JsonValue('unknown')
  unknown
}
