import 'package:equatable/equatable.dart';

class UrlPreviewPresentation with EquatableMixin {
  final String? description;
  final Uri? imageUri;
  final String? title;
  final int? imageHeight;
  final int? imageWidth;

  UrlPreviewPresentation({
    this.description,
    this.imageUri,
    this.title,
    this.imageHeight,
    this.imageWidth,
  });

  @override
  List<Object?> get props => [
        description,
        imageUri,
        title,
        imageHeight,
        imageWidth,
      ];
}
