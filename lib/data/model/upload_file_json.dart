
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'upload_file_json.g.dart';

@JsonSerializable()
class UploadFileResponse with EquatableMixin {

  const UploadFileResponse({
    this.contentUri,
    this.error,
    this.errorCode,
    this.retryAfterMs,
  });

  @JsonKey(name: 'content_uri')
  final String? contentUri;

  final String? errorCode;

  final String? error;

  @JsonKey(name: 'retry_after_ms')
  final String? retryAfterMs;
  
  @override
  List<Object?> get props => [contentUri, errorCode, error, retryAfterMs];

  factory UploadFileResponse.fromJson(Map<String, dynamic> json) =>
      _$UploadFileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UploadFileResponseToJson(this);
}