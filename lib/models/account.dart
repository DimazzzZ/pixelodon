import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

/// Converter for handling both string and integer values in JSON
class StringOrIntConverter implements JsonConverter<String, dynamic> {
  const StringOrIntConverter();

  @override
  String fromJson(dynamic json) {
    if (json == null) return '';
    if (json is String) return json;
    if (json is int) return json.toString();
    if (json is double) return json.toInt().toString();
    return json.toString();
  }

  @override
  dynamic toJson(String object) => object;
}

/// Converter that turns null into empty string
class NullToEmptyStringConverter implements JsonConverter<String, dynamic> {
  const NullToEmptyStringConverter();

  @override
  String fromJson(dynamic json) {
    if (json == null) return '';
    if (json is String) return json;
    return json.toString();
  }

  @override
  dynamic toJson(String object) => object;
}

/// Represents a user account on a Mastodon or Pixelfed instance
@freezed
class Account with _$Account {
  const factory Account({
    /// The account ID
    @StringOrIntConverter() required String id,
    
    /// The username of the account
    required String username,
    
    /// The account's username for use in mentions
    required String acct,
    
    /// The display name of the account
    @JsonKey(name: 'display_name') @NullToEmptyStringConverter() required String displayName,
    
    /// Whether the account is locked (private)
    @Default(false) bool locked,
    
    /// Whether the account is a bot
    @Default(false) bool bot,
    
    /// Whether the account is discoverable
    @Default(true) bool discoverable,
    
    /// Whether the account is a group
    @Default(false) bool group,
    
    /// The time the account was created
    @JsonKey(name: 'created_at') DateTime? createdAt,
    
    /// The account note (bio)
    String? note,
    
    /// The URL of the account's profile page
    String? url,
    
    /// The URL of the account's avatar
    String? avatar,
    
    /// The URL of the account's static avatar (non-animated)
    @JsonKey(name: 'avatar_static') String? avatarStatic,
    
    /// The URL of the account's header image
    String? header,
    
    /// The URL of the account's static header image
    @JsonKey(name: 'header_static') String? headerStatic,
    
    /// The account's follower count
    @JsonKey(name: 'followers_count') @Default(0) int followersCount,
    
    /// The account's following count
    @JsonKey(name: 'following_count') @Default(0) int followingCount,
    
    /// The account's post count
    @JsonKey(name: 'statuses_count') @Default(0) int statusesCount,
    
    /// The time of the account's last status
    @JsonKey(name: 'last_status_at') DateTime? lastStatusAt,
    
    /// The account's fields (key-value pairs displayed on profile)
    List<Field>? fields,
    
    /// Whether the account has been suspended
    @Default(false) bool suspended,
    
    /// Whether the account is muted by the authenticated user
    @Default(false) bool muted,
    
    /// Whether the account is blocked by the authenticated user
    @Default(false) bool blocked,
    
    /// Whether the authenticated user has a pending follow request for this account
    @Default(false) bool requested,
    
    /// Whether the authenticated user is following this account
    @Default(false) bool following,
    
    /// Domain of the account's instance
    String? domain,
    
    /// Whether the account is from a Pixelfed instance
    @Default(false) bool isPixelfed,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);
}

/// Represents a profile field (key-value pair)
@freezed
class Field with _$Field {
  const factory Field({
    /// The key of the field
    required String name,
    
    /// The value of the field
    required String value,
    
    /// The timestamp of when the field was verified
    @JsonKey(name: 'verified_at') DateTime? verifiedAt,
  }) = _Field;

  factory Field.fromJson(Map<String, dynamic> json) => _$FieldFromJson(json);
}
