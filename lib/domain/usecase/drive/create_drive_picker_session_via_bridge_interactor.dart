import 'package:twake_chat/domain/model/drive/drive_exceptions.dart';
import 'package:twake_chat/domain/model/drive/drive_picker_session.dart';
import 'package:twake_chat/domain/model/drive/drive_picker_config.dart';
import 'package:twake_chat/domain/repository/drive/drive_session_repository.dart';

class CreateDrivePickerSessionViaBridgeInteractor {
  const CreateDrivePickerSessionViaBridgeInteractor(this._repository);

  final DriveSessionRepository _repository;

  Future<DrivePickerSession> execute(DrivePickerConfig config) async {
    if (!_repository.isBridgeAvailable) {
      throw const DriveBridgeUnavailableException();
    }
    return _repository.createPickerSessionViaBridge(config);
  }
}
