import 'package:fluffychat/domain/model/media/url_preview.dart';
import 'package:fluffychat/presentation/model/media/url_preview_presentation.dart';

extension UrlPreviewExtension on UrlPreview {
  UrlPreviewPresentation toPresentation() {
    return UrlPreviewPresentation(
      description: description,
      title: titlePreview,
      imageUri: imageUri,
      imageHeight: imageHeight,
      imageWidth: imageWidth,
    );
  }
}
