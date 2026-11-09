import 'package:twake_chat/domain/repository/spaces/space_repository.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';

class GetSpaceUseCase {
  const GetSpaceUseCase(this._repository);

  final SpaceRepository _repository;

  SpaceSummary? execute(String roomId) => _repository.getSpace(roomId);
}
