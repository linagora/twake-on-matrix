import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';

part 'upload_manager.provider.g.dart';

// TODO: [transitional] TW-3302 Bridge (ADR 0037 s3): the upload queue and its
// pending files are shared with the legacy consumers (SendFilesMixin,
// DraftChat, SendFileDialog, UploadFileMixin, Chat); kept alive like that
// GetIt singleton.
@Riverpod(keepAlive: true)
UploadManager uploadManager(Ref ref) => getIt.get<UploadManager>();
