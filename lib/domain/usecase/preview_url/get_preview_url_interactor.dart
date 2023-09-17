import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/preview_url/get_preview_url_failure.dart';
import 'package:fluffychat/domain/app_state/preview_url/get_preview_url_loading.dart';
import 'package:fluffychat/domain/app_state/preview_url/get_preview_url_success.dart';
import 'package:fluffychat/domain/repository/media/media_repository.dart';
import 'package:matrix/matrix.dart';

class GetPreviewURLInteractor {
  final MediaRepository _mediaRepository;

  GetPreviewURLInteractor(this._mediaRepository);

  Stream<Either<Failure, Success>> execute({
    required Uri uri,
    int? preferredPreviewTime,
  }) async* {
    yield const Right(GetPreviewURLLoading());
    try {
      final response = await _mediaRepository.getUrlPreview(
        uri: uri,
        preferredPreviewTime: preferredPreviewTime,
      );
      Logs().d(
        'GetPreviewURLInteractor::execute(): imageUrl - ${response.imageUrl}}',
      );
      yield Right(
        GetPreviewUrlSuccess(urlPreview: response),
      );
    } catch (e) {
      Logs().d(
        'GetPreviewURLInteractor::execute(): Exception - $e}',
      );
      yield Left(GetPreviewURLFailure(e));
    }
  }
}
