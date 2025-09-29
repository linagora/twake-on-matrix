import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/pages/archive/archive.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item.dart';

class ArchiveView extends StatelessWidget {
  final ArchiveController controller;

  const ArchiveView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    var archive = controller.archive;
    return FutureBuilder<List<Room>>(
      future: controller.getArchive(context),
      builder: (BuildContext context, snapshot) => Scaffold(
        appBar: AppBar(
          leading: TwakeIconButton(
            icon: Icons.chevron_left_outlined,
            tooltip: L10n.of(context)!.back,
            onTap: () => context.pop(),
          ),
          title: Text(L10n.of(context)!.archive),
          actions: [
            if (snapshot.data?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton.icon(
                  onPressed: controller.forgetAllAction,
                  label: Text(L10n.of(context)!.clearArchive),
                  icon: const Icon(Icons.cleaning_services_outlined),
                ),
              ),
          ],
        ),
        body: Builder(
          builder: (BuildContext context) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  L10n.of(context)!.oopsSomethingWentWrong,
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              );
            } else {
              archive = snapshot.data;
              if (archive == null || archive!.isEmpty) {
                return const Center(
                  child: Icon(Icons.archive_outlined, size: 80),
                );
              }
              return ListView.builder(
                itemCount: archive!.length,
                itemBuilder: (BuildContext context, int i) => ChatListItem(
                  archive![i],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
