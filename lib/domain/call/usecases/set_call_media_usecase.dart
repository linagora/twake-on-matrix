import 'package:twake_chat/domain/repository/call/call_repository.dart';

class SetCallMediaUseCase {
  const SetCallMediaUseCase(this._repository);

  final CallRepository _repository;

  Future<void> execute({bool? isMicrophoneOn, bool? isCameraOn}) async {
    if (isMicrophoneOn != null) {
      await _repository.setMicrophone(isOn: isMicrophoneOn);
    }
    if (isCameraOn != null) await _repository.setCamera(isOn: isCameraOn);
  }
}
