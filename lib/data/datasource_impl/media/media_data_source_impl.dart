import 'package:fluffychat/data/datasource/media/media_data_source.dart';
import 'package:fluffychat/data/extensions/media/url_preview_response_extension.dart';
import 'package:fluffychat/data/network/media/media_api.dart';
import 'package:fluffychat/domain/model/media/url_preview.dart';

class MediaDataSourceImpl implements MediaDataSource {
  final MediaAPI _mediaAPI;

  MediaDataSourceImpl(this._mediaAPI);

  @override
  Future<UrlPreview> getUrlPreview({
    required Uri uri,
    int? preferredPreviewTime,
  }) async {
    final response = await _mediaAPI.getUrlPreview(
      uri: uri,
      preferredPreviewTime: preferredPreviewTime,
    );
    return response.toUrlPreview();
  }
}
