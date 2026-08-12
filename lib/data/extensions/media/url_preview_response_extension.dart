import 'package:twake_chat/data/model/media/url_preview_response.dart';
import 'package:twake_chat/domain/model/media/url_preview.dart';

extension UrlPreviewResponseExtension on UrlPreviewResponse {
  UrlPreview toUrlPreview() {
    return UrlPreview(
      matrixImageSize: matrixImageSize,
      siteName: siteName,
      imageAlt: imageAlt,
      description: description,
      imageUrl: imageUrl,
      imageHeight: imageHeight,
      imageType: imageType,
      imageWidth: imageWidth,
      imageTitle: imageTitle,
      title: title,
    );
  }
}
