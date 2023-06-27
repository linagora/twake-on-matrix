import 'package:fluffychat/utils/voip/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class CupertinoDialogPermissionCamera extends StatelessWidget {
  const CupertinoDialogPermissionCamera({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        L10n.of(context)!.permissionAccess,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: RichText(
        text: TextSpan(
          text: '${L10n.of(context)!.tapToAllowAccessToYourCamera} ',
          style: Theme.of(context).textTheme.titleSmall,
          children: <TextSpan>[
            TextSpan(text: '${L10n.of(context)!.twake}.', style: Theme.of(context).textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.bold,
            )),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(L10n.of(context)!.dismiss),
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
