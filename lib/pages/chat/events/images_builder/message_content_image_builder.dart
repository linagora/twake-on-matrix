import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/events/images_builder/image_bubble.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/pages/chat/events/images_builder/sending_image_info_widget.dart';
import 'package:fluffychat/presentation/model/file/display_image_info.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_manager.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/utils/extension/image_size_extension.dart';

class MessageImageBuilder extends StatefulWidget {
  final Event event;

  final void Function()? onTapPreview;

  final void Function()? onTapSelectMode;

  final double? maxWidth;

  const MessageImageBuilder({
    super.key,
    required this.event,
    this.onTapPreview,
    this.onTapSelectMode,
    this.maxWidth,
  });

  @override
  State<MessageImageBuilder> createState() => _MessageImageBuilderState();
}

class _MessageImageBuilderState extends State<MessageImageBuilder> {
  Future<MatrixFile?>? _matrixFileFuture;

  Future<MatrixFile?>? _getMatrixFile() async {
    final placeholder = widget.event.getMatrixFile();
    if (placeholder != null) {
      return placeholder;
    }
    final uploadManager = getIt.get<UploadManager>();
    return await uploadManager.getMatrixFile(
      widget.event.eventId,
      room: widget.event.room,
    );
  }

  @override
  void initState() {
    super.initState();
    _matrixFileFuture = _getMatrixFile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _matrixFileFuture,
      builder: (context, snapshot) {
        final matrixFile = snapshot.data;

        DisplayImageInfo? displayImageInfo =
            widget.event.getOriginalResolution()?.getDisplayImageInfo(context);

        if (matrixFile != null && matrixFile.isSendingImageInMobile()) {
          final file = matrixFile as MatrixImageFile;
          displayImageInfo = Size(
            file.width?.toDouble() ?? MessageContentStyle.imageWidth(context),
            file.height?.toDouble() ?? MessageContentStyle.imageHeight(context),
          ).getDisplayImageInfo(context);
          return SendingImageInfoWidget(
            key: ValueKey(widget.event.eventId),
            matrixFile: file,
            event: widget.event,
            onTapPreview: widget.onTapPreview,
            displayImageInfo: displayImageInfo,
            bubbleWidth: widget.maxWidth,
          );
        }
        displayImageInfo ??= DisplayImageInfo(
          size: Size(
            MessageContentStyle.imageWidth(context),
            MessageContentStyle.imageHeight(context),
          ),
          hasBlur: true,
        );
        if (matrixFile != null && matrixFile.isSendingImageInWeb()) {
          final file = matrixFile as MatrixImageFile;
          displayImageInfo = Size(
            file.width?.toDouble() ?? MessageContentStyle.imageWidth(context),
            file.height?.toDouble() ?? MessageContentStyle.imageHeight(context),
          ).getDisplayImageInfo(context);
          return SendingImageInfoWidget(
            key: ValueKey(widget.event.eventId),
            matrixFile: file,
            event: widget.event,
            onTapPreview: widget.onTapPreview,
            displayImageInfo: displayImageInfo,
            bubbleWidth: widget.maxWidth,
          );
        }
        return ImageBubble(
          widget.event,
          bubbleMaxWidth: widget.maxWidth,
          width: displayImageInfo.size.width,
          height: displayImageInfo.size.height,
          fit: BoxFit.cover,
          onTapSelectMode: widget.onTapSelectMode,
          onTapPreview: widget.onTapPreview,
          animated: true,
          thumbnailOnly: true,
        );
      },
    );
  }
}
