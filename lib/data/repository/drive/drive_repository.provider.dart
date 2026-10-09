import 'package:matrix/matrix.dart' show Client;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/datasource_impl/drive/drive_datasource.provider.dart';
import 'package:twake_chat/data/repository/drive/drive_link_message_repository_impl.dart';
import 'package:twake_chat/data/repository/drive/drive_session_repository_impl.dart';
import 'package:twake_chat/domain/repository/drive/drive_link_message_repository.dart';
import 'package:twake_chat/domain/repository/drive/drive_session_repository.dart';

part 'drive_repository.provider.g.dart';

@riverpod
DriveSessionRepository driveSessionRepository(Ref ref) =>
    DriveSessionRepositoryImpl(
      ref.watch(driveBridgeDatasourceProvider),
      ref.watch(driveTokenDatasourceProvider),
    );

@riverpod
DriveLinkMessageRepository driveLinkMessageRepository(Ref ref, Client client) =>
    DriveLinkMessageRepositoryImpl(client);
