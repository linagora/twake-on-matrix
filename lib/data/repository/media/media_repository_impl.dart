import 'package:fluffychat/data/datasource/media/media_data_source.dart';
import 'package:fluffychat/domain/model/media/url_preview.dart';
import 'package:fluffychat/domain/repository/media/media_repository.dart';

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
