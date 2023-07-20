import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/domain/usecase/create_direct_chat_interactor.dart';
import 'package:get_it/get_it.dart';

class CreateDirectChatDi extends BaseDI {
  @override
  String get scopeName => "Create direct chat";

  @override
  void setUp(GetIt get) {
    get.registerSingleton<CreateDirectChatInteractor>(
        CreateDirectChatInteractor());
  }
}
