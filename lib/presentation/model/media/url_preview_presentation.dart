import 'package:equatable/equatable.dart';

class UrlPreviewPresentation with EquatableMixin {
  final String? description;
  final Uri? imageUri;
  final String? title;

  UrlPreviewPresentation({
    this.description,
    this.imageUri,
    this.title,
  });

  @override
  List<Object?> get props => [
        description,
        imageUri,
        title,
      ];
}
