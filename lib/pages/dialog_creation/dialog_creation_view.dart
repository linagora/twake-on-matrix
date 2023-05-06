import 'package:fluffychat/pages/dialog_creation/dialog_creation.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';


class DialogCreationView extends StatelessWidget {

  final DialogCreationController controller;

  const DialogCreationView({
    super.key,
    required this.controller
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context)!.createNewGroup),
      ),
      body: MaxWidthBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: controller.controller,
                autofocus: true,
                autocorrect: false,
                textInputAction: TextInputAction.go,
                onSubmitted: controller.submitAction,
                decoration: InputDecoration(
                  labelText: L10n.of(context)!.optionalGroupName,
                  prefixIcon: const Icon(Icons.people_outlined),
                  hintText: L10n.of(context)!.enterAGroupName,
                ),
              ),
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.public_outlined),
              title: Text(L10n.of(context)!.groupIsPublic),
              value: controller.publicGroup,
              onChanged: controller.setPublicGroup,
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.lock_outlined),
              title: Text(L10n.of(context)!.enableEncryption),
              value: !controller.publicGroup,
              onChanged: null,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.submitAction,
        child: const Icon(Icons.arrow_forward_outlined),
      ),
    );
  }

}