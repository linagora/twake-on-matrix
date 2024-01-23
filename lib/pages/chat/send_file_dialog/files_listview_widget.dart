import 'package:fluffychat/pages/chat/send_file_dialog/hover_actions_widget.dart';
import 'package:fluffychat/presentation/list_notifier.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget.dart';
import 'package:flutter/material.dart';
import 'send_file_dialog_style.dart';

import 'package:matrix/matrix.dart';

typedef OnRemoveFile = void Function(MatrixFile file);

class FilesListViewWidget extends StatelessWidget {
  final ListNotifier<MatrixFile> filesNotifier;

  final OnRemoveFile onRemoveFile;

  final Map<MatrixFile, MatrixImageFile?> thumbnails;

  final Room? room;

  const FilesListViewWidget({
    super.key,
    required this.filesNotifier,
    required this.onRemoveFile,
    required this.thumbnails,
    this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: SendFileDialogStyle.maxHeightFilesListView,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          SendFileDialogStyle.listViewBorderRadius,
        ),
        color: SendFileDialogStyle.listViewBackgroundColor(context),
      ),
      child: SingleChildScrollView(
        child: ValueListenableBuilder(
          valueListenable: filesNotifier,
          builder: (context, files, child) {
            return ListView.builder(
              itemCount: filesNotifier.value.length,
              shrinkWrap: true,
              padding: SendFileDialogStyle.paddingFilesListView,
              itemBuilder: (BuildContext context, int index) {
                final file = filesNotifier.value[index];
                return Padding(
                  padding: SendFileDialogStyle.paddingFileTile,
                  child: HoverActionsWidget(
                    onTap: () => onRemoveFile(file),
                    child: FileTileWidget(
                      mimeType: file.mimeType,
                      filename: file.name,
                      fileType: file.fileExtension,
                      sizeString: file.sizeString,
                      backgroundColor:
                          SendFileDialogStyle.listViewBackgroundColor(context),
                      imageBytes: thumbnails[file]?.bytes,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
