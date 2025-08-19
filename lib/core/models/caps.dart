import 'package:freezed_annotation/freezed_annotation.dart';

part 'caps.freezed.dart';
part 'caps.g.dart';

@freezed
class InstanceCaps with _$InstanceCaps {
  const factory InstanceCaps({
    @Default(false) bool supportsStories,
    @Default(4) int maxMediaPerPost,
    @Default(false) bool supportsAlbums,
    @Default(false) bool supportsDMs,
    @Default(<String, dynamic>{}) Map<String, dynamic> mediaLimits,
    @Default(<String, dynamic>{}) Map<String, dynamic> rateLimits,
  }) = _InstanceCaps;

  factory InstanceCaps.fromJson(Map<String, dynamic> json) => _$InstanceCapsFromJson(json);
}

