import 'package:dio/dio.dart';
import 'package:fluffychat/pages/chat/events/download_video_state.dart';
import 'package:fluffychat/pages/chat/events/event_video_player.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/pages/image_viewer/media_viewer_app_bar.dart';
import 'package:fluffychat/pages/image_viewer/media_viewer_app_bar_web.dart';
import 'package:fluffychat/presentation/mixins/handle_video_download_mixin.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';

class DownloadVideoWidget extends StatefulWidget {
  final Event event;

  const DownloadVideoWidget({
    super.key,
    required this.event,
  });

  @override
  State<StatefulWidget> createState() => _DownloadVideoWidgetState();
}

class _DownloadVideoWidgetState extends State<DownloadVideoWidget>
    with HandleVideoDownloadMixin, PlayVideoActionMixin {
  final _downloadStateNotifier = ValueNotifier(DownloadVideoState.initial);
  String? path;
  final downloadProgressNotifier = ValueNotifier(0.0);
  final cancelToken = CancelToken();

  final ValueNotifier<bool> showAppbarPreview = ValueNotifier(false);

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _downloadAction();
    });
    super.initState();
  }

  @override
  void dispose() {
    cancelToken.cancel();
    downloadProgressNotifier.dispose();
    _downloadStateNotifier.dispose();
    showAppbarPreview.dispose();
    super.dispose();
  }

  void _downloadAction() async {
    _downloadStateNotifier.value = DownloadVideoState.loading;
    try {
      path = await handleDownloadVideoEvent(
        event: widget.event,
        playVideoAction: (path) => playVideoAction(
          context,
          path,
          event: widget.event,
        ),
        progressCallback: (count, total) {
          downloadProgressNotifier.value = count / total;
        },
        cancelToken: cancelToken,
      );
      _downloadStateNotifier.value = DownloadVideoState.done;
    } on MatrixConnectionException catch (e) {
      _downloadStateNotifier.value = DownloadVideoState.failed;
      TwakeSnackBar.show(
        context,
        e.toLocalizedString(context),
      );
    } catch (e, s) {
      _downloadStateNotifier.value = DownloadVideoState.failed;
      TwakeSnackBar.show(
        context,
        e.toLocalizedString(context),
      );
      Logs().e('Error while playing video', e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              MxcImage(
                event: widget.event,
                fit: BoxFit.cover,
              ),
              ValueListenableBuilder<DownloadVideoState>(
                valueListenable: _downloadStateNotifier,
                builder: (context, downloadState, child) {
                  switch (downloadState) {
                    case DownloadVideoState.loading:
                      return InkWell(
                        onTap: downloadState == DownloadVideoState.loading
                            ? null
                            : _downloadAction,
                        child: Center(
                          child: Stack(
                            children: [
                              const CenterVideoButton(
                                icon: Icons.play_arrow,
                              ),
                              SizedBox(
                                width:
                                    MessageContentStyle.videoCenterButtonSize,
                                height:
                                    MessageContentStyle.videoCenterButtonSize,
                                child: ValueListenableBuilder(
                                  valueListenable: downloadProgressNotifier,
                                  builder: (context, progress, child) {
                                    return CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: LinagoraRefColors.material()
                                          .primary[100],
                                      value:
                                          PlatformInfos.isWeb ? null : progress,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    case DownloadVideoState.initial:
                      return InkWell(
                        onTap: _downloadAction,
                        child: const Center(
                          child: CenterVideoButton(
                            icon: Icons.play_arrow,
                          ),
                        ),
                      );
                    case DownloadVideoState.done:
                      return InkWell(
                        onTap: () {
                          if (path != null) {
                            playVideoAction(
                              context,
                              path!,
                              event: widget.event,
                            );
                          }
                        },
                        child: const Center(
                          child: CenterVideoButton(
                            icon: Icons.play_arrow,
                          ),
                        ),
                      );
                    case DownloadVideoState.failed:
                      return InkWell(
                        onTap: _downloadAction,
                        child: const Center(
                          child: CenterVideoButton(
                            icon: Icons.error,
                          ),
                        ),
                      );
                  }
                },
              ),
            ],
          ),
          if (PlatformInfos.isMobile) ...[
            MediaViewerAppBar(
              showAppbarPreviewNotifier: showAppbarPreview,
              event: widget.event,
            ),
          ] else ...[
            MediaViewerAppBarWeb(
              event: widget.event,
            ),
          ],
        ],
      ),
    );
  }
}
