import 'package:freezed_annotation/freezed_annotation.dart';

part 'media.freezed.dart';
part 'media.g.dart';

enum MediaType { image, video }

@freezed
class Media with _$Media {
  const factory Media({
    required String id,
    required String url,
    String? previewUrl,
    String? alt,
    @Default(MediaType.image) MediaType type,
    Map<String, dynamic>? exif,
    // Preserve raw JSON for forward compatibility
    Map<String, dynamic>? raw,
  }) = _Media;

  factory Media.fromJson(Map<String, dynamic> json) => _$MediaFromJson(json);
}

