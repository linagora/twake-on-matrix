import 'package:twake_chat/domain/repository/spaces/space_repository.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';

class GetAddableSpacesUseCase {
  const GetAddableSpacesUseCase(this._repository);

  final SpaceRepository _repository;

  List<SpaceSummary> execute() => _repository.getAddableSpaces();
}
