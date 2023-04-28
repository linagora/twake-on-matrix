import 'package:fluffychat/di/abstract_di.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';

abstract class BaseDI extends AbstractDI {
  @override
  void bind({OnFinishedBind? onFinishedBind}) {
    Logs().d('DI::bind() start binding $scopeName');
    if (currentScope != scopeName) {
      GetIt.instance.pushNewScope(
        init: setUp,
        scopeName: scopeName,
      );
    }
    onFinishedBind?.call();
  }

  String get scopeName;

  String? get currentScope => GetIt.instance.currentScopeName;

  void setUp(GetIt get);

  @override
  Future<void> unbind() async {
    Logs().d("DI::unbind Unbinding $scopeName");
    await GetIt.instance.popScope();
  }
}