import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/media/media_repository.provider.dart';
import 'package:twake_chat/domain/preview_url/usecases/get_url_preview_usecase.dart';

part 'get_url_preview_usecase.provider.g.dart';

@riverpod
GetUrlPreviewUseCase getUrlPreviewUseCase(Ref ref) =>
    GetUrlPreviewUseCase(ref.watch(mediaRepositoryProvider));
