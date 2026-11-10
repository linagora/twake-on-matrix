import 'package:matrix/matrix.dart' show Client;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/drive/datasources_impl/drive_upload_limit_source_impl.dart';
import 'package:twake_chat/domain/drive/sources/drive_upload_limit_source.dart';

part 'drive_upload_limit_source.provider.g.dart';

@riverpod
DriveUploadLimitSource driveUploadLimitSource(Ref ref, Client client) =>
    DriveUploadLimitSourceImpl(client);
