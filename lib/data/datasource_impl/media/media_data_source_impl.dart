import 'package:twake_chat/data/datasource/media/media_data_source.dart';
import 'package:twake_chat/data/extensions/media/url_preview_response_extension.dart';
import 'package:twake_chat/data/network/media/media_api.dart';
import 'package:twake_chat/domain/model/media/url_preview.dart';

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
