import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/presentation/model/chat/upload_file_ui_state.dart';
import 'package:fluffychat/presentation/model/file/display_image_info.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:fluffychat/widgets/mixins/upload_file_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart' hide Visibility;

class SendingImageInfoWidget extends StatefulWidget {
  const SendingImageInfoWidget({
    super.key,
    required this.matrixFile,
    required this.event,
    required this.displayImageInfo,
    this.onTapPreview,
    this.bubbleWidth,
  });

  final MatrixImageFile matrixFile;

  final Event event;

  final void Function()? onTapPreview;

  final DisplayImageInfo displayImageInfo;

  final double? bubbleWidth;

  @override
  State<SendingImageInfoWidget> createState() => _SendingImageInfoWidgetState();
}

class _SendingImageInfoWidgetState extends State<SendingImageInfoWidget>
    with UploadFileMixin {
  @override
  Event get event => widget.event;

  @override
  void dispose() {
    sendingFileProgressNotifier.dispose();
    super.dispose();
  }

  final ValueNotifier<double> sendingFileProgressNotifier = ValueNotifier(0);

  Future<void> _onTap(BuildContext context) async {
    if (widget.onTapPreview != null) {
      await Navigator.of(context, rootNavigator: PlatformInfos.isWeb).push(
        HeroPageRoute(
          builder: (context) {
            return InteractiveViewerGallery(
              itemBuilder: ImageViewer(event: widget.event),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sysColor = LinagoraSysColors.material();
    if (widget.event.status == EventStatus.sent ||
        widget.event.status == EventStatus.synced) {
      sendingFileProgressNotifier.value = 1;
    }

    return Hero(
      tag: widget.event.eventId,
      child: _SendingImageInfoOverlay(
        sendingFileProgressNotifier: sendingFileProgressNotifier,
        uploadFileStateNotifier: uploadFileStateNotifier,
        builder: (progress, uploadState, child) {
          final hasError = uploadState is UploadFileFailedUIState;
          return Stack(
            alignment: Alignment.center,
            children: [
              child!,
              if (progress != 1 || hasError) ...[
                if (!hasError && progress != 1)
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: sysColor.onPrimary,
                  ),
                if (hasError)
                  IconButton(
                    onPressed: () {
                      uploadManager.retryUpload(widget.event);
                    },
                    icon: Icon(
                      Icons.refresh,
                      color: sysColor.primary,
                      size: 24,
                    ),
                    padding: const EdgeInsets.all(4),
                    style: IconButton.styleFrom(
                      backgroundColor: sysColor.onPrimary,
                      shape: const CircleBorder(),
                    ),
                  )
                else if (uploadState is! UploadFileSuccessUIState &&
                    progress != 1)
                  InkWell(
                    child: Icon(Icons.close, color: sysColor.onPrimary),
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
                  if (widget.matrixFile.bytes.isEmpty)
                    SizedBox(
                      width: MessageContentStyle.imageBubbleWidth(
                        widget.displayImageInfo.size.width <
                                (widget.bubbleWidth ?? 0)
                            ? widget.bubbleWidth ?? 0
                            : widget.displayImageInfo.size.width,
                      ),
                      height: MessageContentStyle.imageBubbleHeight(
                        widget.displayImageInfo.size.height,
                      ),
                      child: BlurHash(
                        hash:
                            widget.event.blurHash ??
                            AppConfig.defaultImageBlurHash,
                      ),
                    )
                  else
                    Image.memory(
                      widget.matrixFile.bytes,
                      width: widget.displayImageInfo.size.width,
                      height: widget.displayImageInfo.size.height,
                      cacheHeight: context.getCacheSize(
                        widget.displayImageInfo.size.height,
                      ),
                      cacheWidth: context.getCacheSize(
                        widget.displayImageInfo.size.width,
                      ),
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

class _SendingImageInfoOverlay extends StatelessWidget {
  const _SendingImageInfoOverlay({
    required this.sendingFileProgressNotifier,
    required this.uploadFileStateNotifier,
    required this.builder,
    required this.child,
  });

  final ValueNotifier<double> sendingFileProgressNotifier;
  final ValueNotifier<UploadFileUIState> uploadFileStateNotifier;
  final Widget Function(
    double progress,
    UploadFileUIState uploadState,
    Widget? child,
  )
  builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: sendingFileProgressNotifier,
      builder: (context, progress, child) {
        return ValueListenableBuilder(
          valueListenable: uploadFileStateNotifier,
          builder: (context, uploadState, child) {
            return builder(progress, uploadState, child);
          },
          child: this.child,
        );
      },
    );
  }
}
