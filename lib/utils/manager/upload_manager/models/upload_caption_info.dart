import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'upload_caption_info.g.dart';

@JsonSerializable()
class UploadCaptionInfo with EquatableMixin {
  final String txid;
  final String caption;

  UploadCaptionInfo({required this.caption, required this.txid});

  factory UploadCaptionInfo.fromJson(Map<String, dynamic> json) =>
      _$UploadCaptionInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UploadCaptionInfoToJson(this);

  @override
  List<Object?> get props => [caption, txid];
}
