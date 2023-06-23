import 'package:fluffychat/utils/voip/permission_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class CupertinoDialogPermissionCamera extends StatelessWidget {
  const CupertinoDialogPermissionCamera({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(L10n.of(context)!.tapToAllowAccessToYourCamera),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(L10n.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            PermissionHandlerService().goToSettingsForPermissionActions();
          },
          child: Text(L10n.of(context)!.settings),
        ),
      ],
    );
  }
}
