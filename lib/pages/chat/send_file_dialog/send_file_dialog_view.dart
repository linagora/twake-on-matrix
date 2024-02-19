import 'package:fluffychat/pages/chat/input_bar/input_bar.dart';
import 'package:fluffychat/pages/chat/send_file_dialog/files_listview_widget.dart';
import 'package:fluffychat/pages/chat/send_file_dialog/media_page_view_widget.dart';
import 'package:fluffychat/pages/chat/send_file_dialog/send_file_dialog.dart';
import 'package:fluffychat/pages/chat/send_file_dialog/send_file_dialog_style.dart';
import 'package:fluffychat/presentation/enum/chat/send_media_with_caption_status_enum.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';

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
          width: controller.isSendMediaWithCaption
              ? SendFileDialogStyle.dialogWidthForMedia
              : SendFileDialogStyle.maxDialogWidth,
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
                    child: ValueListenableBuilder(
                      valueListenable: controller.filesNotifier,
                      builder: (context, files, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.isSendMediaWithCaption
                                  ? L10n.of(context)!.sendImages(1)
                                  : L10n.of(context)!.sendFiles(files.length),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            ValueListenableBuilder(
                              valueListenable:
                                  controller.haveErrorFilesNotifier,
                              builder: (context, haveError, child) {
                                if (haveError) {
                                  return child!;
                                }
                                return const SizedBox.shrink();
                              },
                              child: SizedBox(
                                width: SendFileDialogStyle.errorSubHeaderWidth,
                                child: Text(
                                  L10n.of(context)!.errorSendingFiles,
                                  style:
                                      SendFileDialogStyle.subHeaderErrorStyle(
                                    context,
                                  ),
                                  maxLines: 3,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              controller.isSendMediaWithCaption
                  ? MediaPageViewWidget(
                      filesNotifier: controller.filesNotifier,
                      thumbnails: controller.thumbnails,
                    )
                  : FilesListViewWidget(
                      filesNotifier: controller.filesNotifier,
                      room: controller.widget.room,
                      onRemoveFile: controller.onRemoveFile,
                      thumbnails: controller.thumbnails,
                      maxMediaSizeNotifier: controller.maxMediaSizeNotifier,
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
