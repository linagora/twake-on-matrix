import 'dart:io';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/presentation/model/file/display_image_info.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:fluffychat/widgets/mixins/upload_file_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart' hide Visibility;

class SendingImageInfoWidget extends StatefulWidget {
  const SendingImageInfoWidget({
    super.key,
    required this.matrixFile,
    required this.event,
    required this.displayImageInfo,
    this.onTapPreview,
  });

  final MatrixImageFile matrixFile;

  final Event event;

  final void Function()? onTapPreview;

  final DisplayImageInfo displayImageInfo;

  @override
  State<SendingImageInfoWidget> createState() => _SendingImageInfoWidgetState();
}

class _SendingImageInfoWidgetState extends State<SendingImageInfoWidget>
    with UploadFileMixin {
  @override
  Event get event => widget.event;

  final ValueNotifier<double> sendingFileProgressNotifier = ValueNotifier(0);

  void _onTap(BuildContext context) async {
    if (widget.onTapPreview != null) {
      Navigator.of(context, rootNavigator: PlatformInfos.isWeb).push(
        HeroPageRoute(
          builder: (context) {
            return InteractiveViewerGallery(
              itemBuilder: ImageViewer(
                event: widget.event,
                filePath: widget.matrixFile.filePath,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.event.status == EventStatus.sent ||
        widget.event.status == EventStatus.synced) {
      sendingFileProgressNotifier.value = 1;
    }

    return Hero(
      tag: widget.event.eventId,
      child: ValueListenableBuilder<double>(
        key: ValueKey(widget.event.eventId),
        valueListenable: sendingFileProgressNotifier,
        builder: (context, value, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              child!,
              if (sendingFileProgressNotifier.value != 1) ...[
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: LinagoraRefColors.material().primary[100],
                ),
                InkWell(
                  child: Icon(
                    Icons.close,
                    color: LinagoraRefColors.material().primary[100],
                  ),
                  onTap: () {
                    uploadManager.cancelUpload(widget.event);
                  },
                ),
              ],
            ],
          );
        },
        child: Material(
          borderRadius: MessageContentStyle.borderRadiusBubble,
          child: InkWell(
            onTap: () => _onTap(context),
            child: ClipRRect(
              borderRadius: MessageContentStyle.borderRadiusBubble,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.matrixFile.bytes?.isNotEmpty != true ||
                      widget.matrixFile.filePath == null)
                    SizedBox(
                      width: MessageContentStyle.imageBubbleWidth(
                        widget.displayImageInfo.size.width,
                      ),
                      height: MessageContentStyle.imageBubbleHeight(
                        widget.displayImageInfo.size.height,
                      ),
                      child: BlurHash(
                        hash: widget.event.blurHash ??
                            AppConfig.defaultImageBlurHash,
                      ),
                    ),
                  if (!PlatformInfos.isWeb &&
                      widget.matrixFile.filePath != null)
                    Image.file(
                      File(widget.matrixFile.filePath!),
                      width: widget.displayImageInfo.size.width,
                      height: widget.displayImageInfo.size.height,
                      cacheHeight: context
                          .getCacheSize(widget.displayImageInfo.size.height),
                      cacheWidth: context
                          .getCacheSize(widget.displayImageInfo.size.width),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                    ),
                  if (widget.matrixFile.bytes?.isNotEmpty == true)
                    Image.memory(
                      widget.matrixFile.bytes!,
                      width: widget.displayImageInfo.size.width,
                      height: widget.displayImageInfo.size.height,
                      cacheHeight: context
                          .getCacheSize(widget.displayImageInfo.size.height),
                      cacheWidth: context
                          .getCacheSize(widget.displayImageInfo.size.width),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.none,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
