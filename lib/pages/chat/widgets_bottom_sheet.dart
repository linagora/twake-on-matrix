import 'package:flutter/material.dart';

import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/video_call/video_call_webview_page.dart';
import 'package:matrix/matrix.dart';

import 'edit_widgets_dialog.dart';

class WidgetsBottomSheet extends StatelessWidget {
  final Room room;

  const WidgetsBottomSheet({super.key, required this.room});

  Future<void> _openWidget(BuildContext context, MatrixWidget widget) async {
    // MSC1236 URL templating ($matrix_user_id, $matrix_display_name, ...)
    final uri = await widget.buildWidgetUrl();
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await VideoCallWebViewPage.open(context, uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemBuilder: (context, index) {
        if (index == room.widgets.length) {
          return ListTile(
            leading: const Icon(Icons.edit),
            title: Text(L10n.of(context)!.editWidgets),
            onTap: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => EditWidgetsDialog(room: room),
                useRootNavigator: false,
              );
            },
          );
        }
        final widget = room.widgets[index];
        return ListTile(
          title: Text(widget.name ?? widget.url),
          subtitle: Text(widget.type),
          onTap: () => _openWidget(context, widget),
        );
      },
      itemCount: room.widgets.length + 1,
    );
  }
}
