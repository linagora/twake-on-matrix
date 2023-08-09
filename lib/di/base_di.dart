import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';

typedef OnFinishedBind = void Function();

abstract class BaseDI {
  void bind({OnFinishedBind? onFinishedBind}) {
    Logs().d('DI::bind() start binding');
    setUp(getIt);

    onFinishedBind?.call();
  }

  void setUp(GetIt get);
}
