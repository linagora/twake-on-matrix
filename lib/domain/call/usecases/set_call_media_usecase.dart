import 'package:twake_chat/domain/repository/call/call_repository.dart';

class SetCallMediaUseCase {
  const SetCallMediaUseCase(this._repository);

  final CallRepository _repository;

  Future<void> execute({required bool isMicrophoneOn}) =>
      _repository.setMicrophone(isOn: isMicrophoneOn);
}
