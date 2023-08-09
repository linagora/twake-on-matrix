import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'upload_file_json.g.dart';

@JsonSerializable()
class UploadFileResponse with EquatableMixin {
  const UploadFileResponse({
    this.contentUri,
  });

  @JsonKey(name: 'content_uri')
  final String? contentUri;

  @override
  List<Object?> get props => [contentUri];

  factory UploadFileResponse.fromJson(Map<String, dynamic> json) =>
      _$UploadFileResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UploadFileResponseToJson(this);
}
