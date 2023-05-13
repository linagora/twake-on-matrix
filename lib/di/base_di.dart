import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';

typedef OnFinishedBind = void Function();

abstract class BaseDI {
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

  Future<void> unbind() async {
    Logs().d("DI::unbind Unbinding $scopeName");
    await GetIt.instance.popScope();
  }
}