import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/domain/usecase/create_room_interactor.dart';
import 'package:fluffychat/domain/usecase/set_room_avatar_interactor.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';

class CreateRoomDI extends BaseDI {
  @override
  String get scopeName => 'Create Room';

  @override
  void setUp(GetIt get) {
    Logs().d('CreateRoomDI::setUp()');

    get.registerFactory<SetRoomAvatarInteractor>(
      () => SetRoomAvatarInteractor(),
    );

    get.registerFactory<CreateRoomInteractor>(
      () => CreateRoomInteractor(),
    );

    Logs().d('CreateRoomDI::setUp() - done');
  }
}
