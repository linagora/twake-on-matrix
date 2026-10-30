import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/network/media/media_api.dart';

part 'media_api.provider.g.dart';

// TODO: [transitional] MediaAPI still reads the home DioClient from GetIt.
// It holds no state of its own, so this instance and the GetIt singleton used
// by the upload and download extensions share the same client.
@riverpod
MediaAPI mediaApi(Ref ref) => MediaAPI();
