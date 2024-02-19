import 'package:fluffychat/pages/chat/send_file_dialog/hover_actions_widget.dart';
import 'package:fluffychat/pages/chat/send_file_dialog/send_file_dialog_style.dart';
import 'package:fluffychat/presentation/list_notifier.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/widgets/file_widget/file_error_tile_widget_style.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget_style.dart';
import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

typedef OnRemoveFile = void Function(MatrixFile file);

class FilesListViewWidget extends StatelessWidget {
  final ListNotifier<MatrixFile> filesNotifier;

  final OnRemoveFile onRemoveFile;

  final Map<MatrixFile, MatrixImageFile?> thumbnails;

  final Room? room;

  final ValueNotifier<double> maxMediaSizeNotifier;

  const FilesListViewWidget({
    super.key,
    required this.filesNotifier,
    required this.onRemoveFile,
    required this.thumbnails,
    required this.maxMediaSizeNotifier,
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
              itemCount: files.length,
              shrinkWrap: true,
              padding: SendFileDialogStyle.paddingFilesListView,
              itemBuilder: (BuildContext context, int index) {
                final file = files[index];
                return Padding(
                  padding: SendFileDialogStyle.paddingFileTile,
                  child: SendFileDialogActionsWidget(
                    onTap: () => onRemoveFile(file),
                    child: ValueListenableBuilder(
                      valueListenable: maxMediaSizeNotifier,
                      builder: (context, maxMediaSize, _) {
                        return FileTileWidget(
                          mimeType: file.mimeType,
                          filename: file.name,
                          fileType: file.fileExtension,
                          sizeString: file.sizeString,
                          backgroundColor:
                              SendFileDialogStyle.listViewBackgroundColor(
                            context,
                          ),
                          fileTileIcon: file.isFileHaveError(maxMediaSize)
                              ? ImagePaths.icFileError
                              : null,
                          imageBytes: thumbnails[file]?.bytes,
                          style: file.isFileHaveError(maxMediaSize)
                              ? FileErrorTileWidgetStyle()
                              : const FileTileWidgetStyle(),
                        );
                      },
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
