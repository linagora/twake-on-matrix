import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/size_string.dart';
import '../../utils/resize_image.dart';

class SendFileDialog extends StatefulWidget {
  final Room room;
  final List<MatrixFile> files;

  const SendFileDialog({
    required this.room,
    required this.files,
    Key? key,
  }) : super(key: key);

  @override
  SendFileDialogState createState() => SendFileDialogState();
}

class SendFileDialogState extends State<SendFileDialog> {
  bool origImage = false;

  /// Images smaller than 20kb don't need compression.
  static const int minSizeToCompress = 20 * 1024;

  Future<void> _send() async {
    for (var file in widget.files) {
      // ignore: unused_local_variable
      MatrixImageFile? thumbnail;
      if (file is MatrixVideoFile &&
          (file.bytes?.length ?? 0) > minSizeToCompress) {
        await TwakeDialog.showFutureLoadingDialogFullScreen(
          future: () async {
            file = await file.resizeVideo();
            thumbnail = await file.getVideoThumbnail();
          },
        );
      }
      // ignore: unused_local_variable
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      widget.room
          .sendFileOnWebEvent(
        file,
        thumbnail: thumbnail,
        shrinkImageMaxDimension: origImage ? null : 1600,
      )
          .catchError((e) {
        TwakeSnackBar.show(context, (e as Object).toLocalizedString(context));
        return null;
      });
    }
    Navigator.of(context, rootNavigator: false).pop();

    return;
  }

  @override
  Widget build(BuildContext context) {
    var sendStr = L10n.of(context)!.sendFile;
    final bool allFilesAreImages =
        widget.files.every((file) => file is MatrixImageFile);
    final sizeString = widget.files
        .fold<double>(0, (p, file) => p + (file.bytes?.length ?? 0))
        .sizeString;
    final fileName = widget.files.length == 1
        ? widget.files.single.name
        : L10n.of(context)!.countFiles(widget.files.length.toString());

    if (allFilesAreImages) {
      sendStr = L10n.of(context)!.sendImage;
    } else if (widget.files.every((file) => file is MatrixAudioFile)) {
      sendStr = L10n.of(context)!.sendAudio;
    } else if (widget.files.every((file) => file is MatrixVideoFile)) {
      sendStr = L10n.of(context)!.sendVideo;
    }
    Widget contentWidget;
    if (allFilesAreImages) {
      contentWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: Image.memory(
              widget.files.first.bytes!,
              fit: BoxFit.contain,
            ),
          ),
        ],
      );
    } else {
      contentWidget = Text('$fileName ($sizeString)');
    }
    return AlertDialog(
      title: Text(sendStr),
      content: contentWidget,
      actions: <Widget>[
        TextButton(
          onPressed: () {
            // just close the dialog
            Navigator.of(context, rootNavigator: false).pop();
          },
          child: Text(L10n.of(context)!.cancel),
        ),
        TextButton(
          onPressed: _send,
          child: Text(L10n.of(context)!.send),
        ),
      ],
    );
  }
}
