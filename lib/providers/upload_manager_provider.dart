import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';

part 'upload_manager_provider.g.dart';

// TODO: [transitional] #3392 - `UploadManager` keeps state that the legacy
// chat view shares, so it stays in get_it until that view moves.
@Riverpod(keepAlive: true)
UploadManager uploadManager(Ref ref) => getIt.get<UploadManager>();
