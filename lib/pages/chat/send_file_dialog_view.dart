import 'package:fluffychat/pages/chat/input_bar/input_bar.dart';
import 'package:fluffychat/pages/chat/send_file_dialog.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/presentation/enum/chat/send_media_with_caption_status_enum.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/pages/chat/send_file_dialog_style.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

class SendFileDialogView extends StatelessWidget {
  final SendFileDialogController controller;

  const SendFileDialogView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius:
            BorderRadius.circular(SendFileDialogStyle.dialogBorderRadius),
        child: Container(
          width: SendFileDialogStyle.dialogWidth,
          constraints: const BoxConstraints(
            maxHeight: SendFileDialogStyle.maxDialogHeight,
          ),
          padding: const EdgeInsets.all(SendFileDialogStyle.dialogBorderRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Padding(
                    padding: SendFileDialogStyle.headerPadding,
                    child: Text(
                      controller.isSendMediaWithCaption
                          ? L10n.of(context)!.sendImages(1)
                          : L10n.of(context)!
                              .sendFiles(controller.files.length),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              controller.isSendMediaWithCaption
                  ? _MediaPageViewWidget(files: controller.files)
                  : _FilesListViewWidget(
                      files: controller.files,
                      room: controller.widget.room,
                    ),
              const SizedBox(height: 16.0),
              InkWell(
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                focusColor: Colors.transparent,
                onTap: controller.requestFocusCaptions,
                child: InputBar(
                  typeAheadKey: controller.sendFileDialogTypeAheadKey,
                  maxLines: 5,
                  minLines: 1,
                  focusSuggestionController:
                      controller.focusSuggestionController,
                  room: controller.widget.room,
                  controller: controller.textEditingController,
                  textInputAction: null,
                  decoration:
                      SendFileDialogStyle.bottomBarInputDecoration(context),
                  keyboardType: TextInputType.multiline,
                  typeAheadFocusNode: controller.captionsFocusNode,
                  autofocus: !PlatformInfos.isMobile,
                  onSubmitted: (_) => controller.send(),
                ),
              ),
              SendFileDialogStyle.spaceBwInputBarAndButton,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(
                      SendMediaWithCaptionStatus.cancel,
                    ),
                    style: ButtonStyle(
                      shape: MaterialStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            SendFileDialogStyle.buttonBorderRadius,
                          ),
                        ),
                      ),
                      padding: const MaterialStatePropertyAll(
                        SendFileDialogStyle.buttonPadding,
                      ),
                    ),
                    child: Text(
                      L10n.of(context)!.cancel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  const SizedBox(
                    width: 4.0,
                  ),
                  TextButton(
                    onPressed: controller.send,
                    autofocus: true,
                    style: ButtonStyle(
                      shape: MaterialStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            SendFileDialogStyle.buttonBorderRadius,
                          ),
                        ),
                      ),
                      backgroundColor: MaterialStatePropertyAll(
                        Theme.of(context).colorScheme.primary,
                      ),
                      padding: const MaterialStatePropertyAll(
                        SendFileDialogStyle.buttonPadding,
                      ),
                    ),
                    child: Text(
                      L10n.of(context)!.send,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: SendFileDialogStyle.listViewBackgroundColor(
                              context,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaPageViewWidget extends StatelessWidget {
  const _MediaPageViewWidget({
    required this.files,
  });

  final List<MatrixFile> files;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context, rootNavigator: PlatformInfos.isWeb).push(
          HeroPageRoute(
            builder: (context) {
              return InteractiveViewerGallery(
                itemBuilder: ImageViewer(
                  imageData: files.first.bytes,
                ),
              );
            },
          ),
        );
      },
      child: SizedBox(
        width: SendFileDialogStyle.imageSize,
        height: SendFileDialogStyle.imageSize,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            SendFileDialogStyle.imageBorderRadius,
          ),
          child: files.first.bytes != null
              ? Image.memory(
                  files.first.bytes!,
                  fit: BoxFit.cover,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _FilesListViewWidget extends StatelessWidget {
  final List<MatrixFile> files;

  final Room? room;

  const _FilesListViewWidget({
    required this.files,
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
        child: ListView.builder(
          itemCount: files.length,
          shrinkWrap: true,
          padding: SendFileDialogStyle.paddingFilesListView,
          itemBuilder: (BuildContext context, int index) {
            final file = files[index];
            final child = Padding(
              padding: SendFileDialogStyle.paddingFileTile,
              child: FileTileWidget(
                mimeType: file.mimeType,
                filename: file.name,
                fileType: file.fileExtension,
                sizeString: file.sizeString,
                backgroundColor:
                    SendFileDialogStyle.listViewBackgroundColor(context),
              ),
            );
            Future<MatrixImageFile?>? getThumbnailFuture;
            if (file is MatrixImageFile) {
              getThumbnailFuture = room?.generateThumbnail(file);
            } else if (file is MatrixVideoFile) {
              getThumbnailFuture = room?.generateVideoThumbnail(file);
            } else {
              return child;
            }

            return FutureBuilder(
              future: getThumbnailFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return child;
                }
                return Padding(
                  padding: SendFileDialogStyle.paddingFileTile,
                  child: FileTileWidget(
                    mimeType: file.mimeType,
                    filename: file.name,
                    fileType: file.fileExtension,
                    sizeString: file.sizeString,
                    backgroundColor:
                        SendFileDialogStyle.listViewBackgroundColor(context),
                    imageBytes: snapshot.data?.bytes,
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
