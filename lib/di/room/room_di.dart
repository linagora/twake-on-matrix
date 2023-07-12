import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/domain/usecase/room/create_new_group_chat_interactor.dart';
import 'package:fluffychat/domain/usecase/room/upload_avatar_new_group_chat_interactor.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';

class CreateNewRoomDI extends BaseDI {
  @override
  String get scopeName => 'Create new Room';

  @override
  void setUp(GetIt get) {
    Logs().d('CreateRoomDI::setUp()');

    get.registerSingleton<CreateNewGroupChatInteractor>(CreateNewGroupChatInteractor());

    get.registerSingleton<UploadAvatarNewGroupChatInteractor>(UploadAvatarNewGroupChatInteractor());

    Logs().d('CreateNewRoomDI::setUp() - done');
  }
}