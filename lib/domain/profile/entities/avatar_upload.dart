import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'avatar_upload.freezed.dart';

@freezed
sealed class AvatarUpload with _$AvatarUpload {
  const factory AvatarUpload.fromFile({
    required String path,
    required String name,
    String? mimeType,
  }) = AvatarFromFile;

  const factory AvatarUpload.fromBytes({
    required Uint8List bytes,
    required String name,
    String? mimeType,
  }) = AvatarFromBytes;
}
