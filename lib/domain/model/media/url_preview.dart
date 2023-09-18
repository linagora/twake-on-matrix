import 'package:equatable/equatable.dart';

class UrlPreview with EquatableMixin {
  final int? matrixImageSize;
  final String? siteName;
  final String? imageAlt;
  final String? description;
  final String? imageUrl;
  final int? imageHeight;
  final int? imageWidth;
  final String? imageType;
  final String? imageTitle;
  final String? title;

  UrlPreview({
    this.matrixImageSize,
    this.siteName,
    this.imageAlt,
    this.description,
    this.imageUrl,
    this.imageHeight,
    this.imageWidth,
    this.imageType,
    this.imageTitle,
    this.title,
  });

  Uri? get imageUri => imageUrl != null ? Uri.tryParse(imageUrl!) : null;

  String? get titlePreview => title ?? siteName ?? imageTitle;

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
