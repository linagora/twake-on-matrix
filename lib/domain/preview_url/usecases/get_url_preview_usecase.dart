import 'package:twake_chat/domain/model/media/url_preview.dart';
import 'package:twake_chat/domain/preview_url/exceptions/get_url_preview_exception.dart';
import 'package:twake_chat/domain/repository/media/media_repository.dart';

class GetUrlPreviewUseCase {
  const GetUrlPreviewUseCase(this._repository);

  final MediaRepository _repository;

  /// Fetches the preview of [uri].
  ///
  /// Throws a [GetUrlPreviewException] holding the cause when the repository
  /// throws an [Exception]. An [Error] is a programming mistake and surfaces
  /// unchanged.
  Future<UrlPreview> execute({
    required Uri uri,
    int? preferredPreviewTime,
  }) async {
    try {
      return await _repository.getUrlPreview(
        uri: uri,
        preferredPreviewTime: preferredPreviewTime,
      );
    } on Exception catch (e, s) {
      Error.throwWithStackTrace(GetUrlPreviewException(e), s);
    }
  }
}
