import 'package:fluffychat/di/di_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';

typedef OnFinishedBind = void Function();

abstract class BaseDI implements DIInterface {
  @override
  void bind({OnFinishedBind? onFinishedBind}) { 
    debugPrint('start binding $scopeName');
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
    debugPrint("Unbinding $scopeName");
    await GetIt.instance.popScope();
    debugPrint("finished unbinding $scopeName");
  }
}