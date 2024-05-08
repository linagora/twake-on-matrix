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
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart' hide Visibility;

class SendingImageInfoWidget extends StatelessWidget {
  SendingImageInfoWidget({
    super.key,
    required this.matrixFile,
    required this.event,
    required this.displayImageInfo,
    this.onTapPreview,
  });

  final MatrixImageFile matrixFile;

  final Event event;

  final void Function()? onTapPreview;

  final ValueNotifier<double> sendingFileProgressNotifier = ValueNotifier(0);

  final DisplayImageInfo displayImageInfo;

  void _onTap(BuildContext context) async {
    if (onTapPreview != null) {
      Navigator.of(context, rootNavigator: PlatformInfos.isWeb).push(
        HeroPageRoute(
          builder: (context) {
            return InteractiveViewerGallery(
              itemBuilder: ImageViewer(
                event: event,
                filePath: matrixFile.filePath,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (event.status == EventStatus.sent ||
        event.status == EventStatus.synced) {
      sendingFileProgressNotifier.value = 1;
    }

    return Hero(
      tag: event.eventId,
      child: ValueListenableBuilder<double>(
        key: ValueKey(event.eventId),
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
                Icon(
                  Icons.close,
                  color: LinagoraRefColors.material().primary[100],
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
                  if (matrixFile.bytes?.isNotEmpty != true ||
                      matrixFile.filePath == null)
                    SizedBox(
                      width: MessageContentStyle.imageBubbleWidth(
                        displayImageInfo.size.width,
                      ),
                      height: MessageContentStyle.imageBubbleHeight(
                        displayImageInfo.size.height,
                      ),
                      child: BlurHash(
                        hash: event.blurHash ?? AppConfig.defaultImageBlurHash,
                      ),
                    ),
                  if (!PlatformInfos.isWeb && matrixFile.filePath != null)
                    Image.file(
                      File(matrixFile.filePath!),
                      width: displayImageInfo.size.width,
                      height: displayImageInfo.size.height,
                      cacheHeight:
                          context.getCacheSize(displayImageInfo.size.height),
                      cacheWidth:
                          context.getCacheSize(displayImageInfo.size.width),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                    ),
                  if (matrixFile.bytes?.isNotEmpty == true)
                    Image.memory(
                      matrixFile.bytes!,
                      width: displayImageInfo.size.width,
                      height: displayImageInfo.size.height,
                      cacheHeight:
                          context.getCacheSize(displayImageInfo.size.height),
                      cacheWidth:
                          context.getCacheSize(displayImageInfo.size.width),
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
