import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource/media/media_data_source.dart';
import 'package:twake_chat/data/datasource_impl/media/media_data_source_impl.dart';
import 'package:twake_chat/data/network/media/media_api.provider.dart';

part 'media_data_source.provider.g.dart';

@riverpod
MediaDataSource mediaDataSource(Ref ref) =>
    MediaDataSourceImpl(ref.watch(mediaApiProvider));
