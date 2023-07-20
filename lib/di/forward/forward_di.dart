import 'package:fluffychat/di/base_di.dart';
import 'package:fluffychat/domain/usecase/forward/forward_message_interactor.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';

class ForwardDI extends BaseDI {
  @override
  String get scopeName => 'Create Forward';

  @override
  void setUp(GetIt get) {
    Logs().d('ForwardDI::setUp()');

    get.registerSingleton<ForwardMessageInteractor>(ForwardMessageInteractor());

    Logs().d('ForwardDI::setUp() - done');
  }
}
