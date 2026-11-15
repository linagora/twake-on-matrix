import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';

part 'upload_manager_provider.g.dart';

/// Bridge: the upload queue is shared with legacy consumers including
/// `SendFilesMixin` and `SendFileDialog`.
/// TODO: [transitional] ToM-Private#3: remove this bridge after they migrate.
@Riverpod(keepAlive: true)
UploadManager uploadManager(Ref ref) => getIt.get<UploadManager>();
