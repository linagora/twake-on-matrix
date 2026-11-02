import 'package:twake_chat/domain/repository/spaces/space_repository.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';

class GetSpaceChildrenUseCase {
  const GetSpaceChildrenUseCase(this._repository);

  final SpaceRepository _repository;

  Future<List<SpaceChannel>> execute(String spaceId) =>
      _repository.getSpaceChildren(spaceId);
}
