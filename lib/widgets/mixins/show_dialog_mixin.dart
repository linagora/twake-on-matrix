import 'package:fluffychat/di/abstract_di.dart';
import 'package:fluffychat/di/base_di.dart';
import 'package:flutter/material.dart';

mixin ShowDialogMixin {
  
  void showDialogWithDependency({
    required BuildContext context,
    required BaseDI di,
    required RoutePageBuilder pageBuilder,
    OnFinishedBind? onFinishedBind,
  }) {
    di.bind(onFinishedBind: onFinishedBind);
    showGeneralDialog(context: context, pageBuilder: pageBuilder)
      .whenComplete(() async => di.unbind());

  }
}