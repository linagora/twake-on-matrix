import 'package:matrix/matrix.dart' show Client;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/repository/drive/drive_repository.provider.dart';
import 'package:twake_chat/domain/usecase/drive/create_drive_picker_session_via_bridge_interactor.dart';
import 'package:twake_chat/domain/usecase/drive/send_drive_links_interactor.dart';

part 'drive_interactor.provider.g.dart';

@riverpod
CreateDrivePickerSessionViaBridgeInteractor
createDrivePickerSessionViaBridgeInteractor(Ref ref) =>
    CreateDrivePickerSessionViaBridgeInteractor(
      ref.watch(driveSessionRepositoryProvider),
    );

@riverpod
SendDriveLinksInteractor sendDriveLinksInteractor(Ref ref, Client client) =>
    SendDriveLinksInteractor(
      ref.watch(driveLinkMessageRepositoryProvider(client)),
    );
