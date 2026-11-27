import 'package:twake_chat/domain/repository/call/call_repository.dart';

class SetCallSpeakerUseCase {
  const SetCallSpeakerUseCase(this._repository);

  final CallRepository _repository;

  Future<void> execute({required bool isOn, required bool isForced}) =>
      _repository.setSpeaker(isOn: isOn, isForced: isForced);
}
