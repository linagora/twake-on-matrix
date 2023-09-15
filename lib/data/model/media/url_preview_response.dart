import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'url_preview_response.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class UrlPreviewResponse with EquatableMixin {
  @JsonKey(name: 'matrix:image:size')
  final int? matrixImageSize;
  @JsonKey(name: 'og:site_name')
  final String? siteName;
  @JsonKey(name: 'og:image:alt')
  final String? imageAlt;
  @JsonKey(name: 'og:description')
  final String? description;
  @JsonKey(name: 'og:image')
  final String? imageUrl;
  @JsonKey(name: 'og:image:height')
  final int? imageHeight;
  @JsonKey(name: 'og:image:width')
  final int? imageWidth;
  @JsonKey(name: 'og:image:type')
  final String? imageType;
  @JsonKey(name: 'og:image:title')
  final String? imageTitle;
  @JsonKey(name: 'og:title')
  final String? title;

  UrlPreviewResponse({
    this.matrixImageSize,
    this.siteName,
    this.imageAlt,
    this.description,
    this.imageUrl,
    this.imageHeight,
    this.imageType,
    this.imageWidth,
    this.imageTitle,
    this.title,
  });

  factory UrlPreviewResponse.fromJson(Map<String, dynamic> json) =>
      _$UrlPreviewResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UrlPreviewResponseToJson(this);

  @override
  List<Object?> get props => [
        matrixImageSize,
        siteName,
        imageAlt,
        description,
        imageUrl,
        imageHeight,
        imageType,
        imageWidth,
        imageTitle,
        title,
      ];
}
