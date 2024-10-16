import 'package:fluffychat/presentation/model/chat/upload_file_ui_state.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/int_extension.dart';
import 'package:fluffychat/widgets/file_widget/base_file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/circular_loading_download_widget.dart';
import 'package:fluffychat/widgets/file_widget/message_file_tile_style.dart';
import 'package:fluffychat/widgets/mixins/upload_file_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matrix/matrix.dart';

class MessageUploadingContent extends StatefulWidget {
  final Event event;
  final MessageFileTileStyle style;

  const MessageUploadingContent({
    super.key,
    required this.event,
    required this.style,
  });

  @override
  State<MessageUploadingContent> createState() =>
      _MessageUploadingContentState();
}

class _MessageUploadingContentState extends State<MessageUploadingContent>
    with UploadFileMixin<MessageUploadingContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.style.paddingFileTileAll,
      decoration: ShapeDecoration(
        color: widget.style
            .backgroundColor(context, ownMessage: event.isOwnMessage),
        shape: RoundedRectangleBorder(
          borderRadius: widget.style.borderRadius,
        ),
      ),
      child: Row(
        crossAxisAlignment: widget.style.crossAxisAlignment,
        children: [
          ValueListenableBuilder(
            valueListenable: uploadFileStateNotifier,
            builder: (context, uploadFileState, child) {
              double? uploadProgress;
              final hasError = uploadFileState is UploadFileFailedUIState;
              if (uploadFileState is UploadingFileUIState) {
                if (uploadFileState.total == null ||
                    uploadFileState.receive == null) {
                  uploadProgress = null;
                } else {
                  uploadProgress =
                      uploadFileState.receive! / uploadFileState.total!;
                }
              } else if (uploadFileState is UploadFileUISateInitial) {
                uploadProgress = 0;
              } else if (uploadFileState is UploadFileSuccessUIState) {
                return Row(
                  crossAxisAlignment: widget.style.crossAxisAlignment,
                  children: [
                    SvgPicture.asset(
                      widget.event.mimeType.getIcon(
                        fileType: widget.event.fileType,
                      ),
                      width: widget.style.iconSize,
                      height: widget.style.iconSize,
                    ),
                  ],
                );
              }
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: widget.style.marginDownloadIcon,
                    width: widget.style.iconSize,
                    height: widget.style.iconSize,
                    decoration: BoxDecoration(
                      color: widget.style.iconBackgroundColor(
                        hasError: hasError,
                        context: context,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (uploadProgress != 0 && !hasError)
                    SizedBox(
                      width: widget.style.circularProgressLoadingSize,
                      height: widget.style.circularProgressLoadingSize,
                      child: CircularLoadingDownloadWidget(
                        style: widget.style,
                        downloadProgress:
                            uploadProgress != 1 ? uploadProgress : null,
                      ),
                    ),
                  Container(
                    width: widget.style.downloadIconSize,
                    decoration: BoxDecoration(
                      color: widget.style.iconBackgroundColor(
                        hasError: hasError,
                        context: context,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasError ? Icons.error_outline : Icons.close,
                      key: ValueKey(uploadProgress),
                      color: Theme.of(context).colorScheme.surface,
                      size: widget.style.downloadIconSize,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (uploadFileState is UploadFileSuccessUIState) {
                        return;
                      }
                      uploadManager.cancelUpload(event);
                    },
                    mouseCursor: SystemMouseCursors.click,
                    child: SizedBox(
                      width: widget.style.downloadIconSize * 1.5,
                      height: widget.style.downloadIconSize * 1.5,
                    ),
                  ),
                ],
              );
            },
          ),
          widget.style.paddingRightIcon,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 4.0),
                FileNameText(
                  filename: widget.event.filename,
                  style: widget.style,
                ),
                Row(
                  children: [
                    if (widget.event.sizeString != null)
                      ValueListenableBuilder<UploadFileUIState>(
                        valueListenable: uploadFileStateNotifier,
                        builder: ((context, uploadFileState, child) {
                          if (uploadFileState is UploadingFileUIState &&
                              uploadFileState.total != null &&
                              uploadFileState.receive != null &&
                              uploadFileState.total! >= IntExtension.oneKB) {
                            return Text(
                              '${uploadFileState.receive!.bytesToMB(placeDecimal: 2)} MB / ${uploadFileState.total!.bytesToMB(placeDecimal: 2)} MB',
                              style: widget.style.textInformationStyle(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ),
                    Text(
                      " · ",
                      style: widget.style.textInformationStyle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Flexible(
                      child: Text(
                        widget.event.mimeType.getFileType(
                          context,
                          fileType: widget.event.fileType,
                        ),
                        style: widget.style.textInformationStyle(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                widget.style.paddingBottomText,
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Event get event => widget.event;
}
