import 'package:fluffychat/domain/model/media/url_preview.dart';

abstract class MediaDataSource {
  Future<UrlPreview> getUrlPreview({
    required Uri uri,
    int? preferredPreviewTime,
  });
}
