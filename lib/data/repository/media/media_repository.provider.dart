import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/media/media_data_source.provider.dart';
import 'package:twake_chat/data/repository/media/media_repository_impl.dart';
import 'package:twake_chat/domain/repository/media/media_repository.dart';

part 'media_repository.provider.g.dart';

@riverpod
MediaRepository mediaRepository(Ref ref) =>
    MediaRepositoryImpl(ref.watch(mediaDataSourceProvider));
