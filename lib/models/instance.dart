import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'instance.freezed.dart';
part 'instance.g.dart';

/// Represents a Mastodon or Pixelfed instance
@freezed
class Instance with _$Instance {
  const factory Instance({
    /// The domain name of the instance
    required String domain,
    
    /// The name of the instance
    required String name,
    
    /// The description of the instance
    String? description,
    
    /// The version of the software running on the instance
    String? version,
    
    /// The URL of the instance's thumbnail
    String? thumbnail,
    
    /// The languages supported by the instance
    List<String>? languages,
    
    /// The maximum allowed characters per post
    int? maxCharsPerPost,
    
    /// The maximum allowed media attachments per post
    int? maxMediaAttachments,
    
    /// Whether the instance is a Pixelfed instance
    @Default(false) bool isPixelfed,
    
    /// Whether the instance supports stories
    @Default(false) bool supportsStories,
    
    /// The URL of the instance's terms of service
    String? tosUrl,
    
    /// The URL of the instance's privacy policy
    String? privacyPolicyUrl,
    
    /// The contact email of the instance
    String? contactEmail,
  }) = _Instance;

  factory Instance.fromJson(Map<String, dynamic> json) => _$InstanceFromJson(json);
}
