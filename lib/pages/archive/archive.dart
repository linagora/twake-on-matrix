import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/archive/archive_view.dart';
import 'package:fluffychat/widgets/matrix.dart';

class Archive extends StatefulWidget {
  const Archive({super.key});

  @override
  ArchiveController createState() => ArchiveController();
}

class ArchiveController extends State<Archive> {
  List<Room>? archive;

  Future<List<Room>> getArchive(BuildContext context) async {
    final archive = this.archive;
    if (archive != null) return archive;
    return this.archive = await Matrix.of(context).client.loadArchive();
  }

  void forgetAllAction() async {
    final archive = this.archive;
    if (archive == null) return;
    if (await showOkCancelAlertDialog(
          useRootNavigator: false,
          context: context,
          title: L10n.of(context)!.areYouSure,
          okLabel: L10n.of(context)!.yes,
          cancelLabel: L10n.of(context)!.cancel,
          message: L10n.of(context)!.clearArchive,
        ) !=
        OkCancelResult.ok) {
      return;
    }
    await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        while (archive.isNotEmpty) {
          Logs().v('Forget room ${archive.last.getLocalizedDisplayname()}');
          await archive.last.forget();
          archive.removeLast();
        }
      },
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => ArchiveView(this);
}
