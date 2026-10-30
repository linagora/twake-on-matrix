import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/model/media/url_preview.dart';
import 'package:twake_chat/domain/preview_url/usecases/get_url_preview_usecase.provider.dart';

part 'url_preview_provider.g.dart';

const int defaultPreferredPreviewTimeInMilliseconds = 2000;

/// Preview of [uri], fetched once per link while a widget shows it.
@riverpod
Future<UrlPreview> urlPreview(Ref ref, Uri uri) async {
  try {
    return await ref
        .watch(getUrlPreviewUseCaseProvider)
        .execute(
          uri: uri,
          preferredPreviewTime: defaultPreferredPreviewTimeInMilliseconds,
        );
  } catch (e, s) {
    Logs().e('urlPreviewProvider: $e', e, s);
    rethrow;
  }
}
