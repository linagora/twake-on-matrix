import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/search/public_room_state.dart';
import 'package:fluffychat/domain/repository/public_room_reposity.dart';
import 'package:matrix/matrix.dart';

class PublicRoomInteractor {
  final PublicRoomRepository _publicRoomRepository =
      getIt.get<PublicRoomRepository>();

  Stream<Either<Failure, Success>> execute({
    PublicRoomQueryFilter? filter,
    String? server,
    int? limit,
  }) async* {
    try {
      final response = await _publicRoomRepository.search(
        filter: filter,
        server: server,
        limit: limit,
      );

      yield Right(PublicRoomSuccess(publicRoomsChunk: response.chunk));
    } catch (e) {
      Logs().e(
        'PublicRoomInteractor::execute(): Exception - $e}.',
      );
      yield Left(PublicRoomFailed(exception: e));
    }
  }
}
