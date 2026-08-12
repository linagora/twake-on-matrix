import 'package:twake_chat/data/datasource/media/media_data_source.dart';
import 'package:twake_chat/domain/model/media/url_preview.dart';
import 'package:twake_chat/domain/repository/media/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  final MediaDataSource _mediaDataSource;

  MediaRepositoryImpl(this._mediaDataSource);

  @override
  Future<UrlPreview> getUrlPreview({
    required Uri uri,
    int? preferredPreviewTime,
  }) {
    return _mediaDataSource.getUrlPreview(
      uri: uri,
      preferredPreviewTime: preferredPreviewTime,
    );
  }
}
