import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';

part 'upload_manager_provider.g.dart';

/// The upload manager, a process-wide singleton (`UploadManager()` always
/// returns the same instance), so widgets read it through Riverpod.
@Riverpod(keepAlive: true)
UploadManager uploadManager(Ref ref) => UploadManager();
