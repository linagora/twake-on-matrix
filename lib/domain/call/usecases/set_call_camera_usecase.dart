import 'package:twake_chat/domain/repository/call/call_repository.dart';

class SetCallCameraUseCase {
  const SetCallCameraUseCase(this._repository);

  final CallRepository _repository;

  Future<void> execute({required bool isOn}) =>
      _repository.setCamera(isOn: isOn);
}
