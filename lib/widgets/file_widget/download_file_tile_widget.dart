import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/message_file_tile_style.dart';
import 'package:flutter/material.dart';

class DownloadFileTileWidget extends StatefulWidget {
  const DownloadFileTileWidget({
    super.key,
    this.style = const MessageFileTileStyle(),
    required this.mimeType,
    required this.filename,
    this.highlightText,
    this.fileType,
    this.sizeString,
    required this.downloadFileStateNotifier,
    this.onCancelDownload,
  });

  final TwakeMimeType mimeType;
  final String filename;
  final MessageFileTileStyle style;
  final String? highlightText;
  final String? sizeString;
  final String? fileType;
  final ValueNotifier<DownloadPresentationState> downloadFileStateNotifier;
  final VoidCallback? onCancelDownload;

  @override
  State<DownloadFileTileWidget> createState() => _DownloadFileTileWidgetState();
}

class _DownloadFileTileWidgetState extends State<DownloadFileTileWidget>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      padding: widget.style.paddingFileTileAll,
      decoration: ShapeDecoration(
        color: widget.style.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: widget.style.borderRadius,
        ),
      ),
      child: Row(
        crossAxisAlignment: widget.style.crossAxisAlignment,
        children: [
          ValueListenableBuilder(
            valueListenable: widget.downloadFileStateNotifier,
            builder: (context, downloadFileState, child) {
              double? downloadProgress;
              if (downloadFileState is DownloadingPresentationState) {
                if (downloadFileState.total == null ||
                    downloadFileState.receive == null) {
                  downloadProgress = null;
                } else {
                  downloadProgress =
                      downloadFileState.receive! / downloadFileState.total!;
                }
              } else if (downloadFileState is NotDownloadPresentationState) {
                downloadProgress = 0;
              }
              if (downloadProgress == 0) {
                return Padding(
                  padding: widget.style.paddingDownloadFileIcon,
                  child: Icon(
                    Icons.file_download_rounded,
                    size: widget.style.iconSize,
                  ),
                );
              }
              return Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _animation!,
                    child: CircularProgressIndicator(
                      strokeWidth: widget.style.strokeWidthLoading,
                      value: downloadProgress,
                    ),
                  ),
                  IconButton(
                    onPressed:
                        PlatformInfos.isWeb ? null : widget.onCancelDownload,
                    icon: Icon(
                      Icons.close,
                      size: widget.style.cancelButtonSize,
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
                  filename: widget.filename,
                  highlightText: widget.highlightText,
                  style: widget.style,
                ),
                Row(
                  children: [
                    if (widget.sizeString != null)
                      TextInformationOfFile(
                        value: widget.sizeString!,
                        style: widget.style,
                        downloadFileStateNotifier:
                            widget.downloadFileStateNotifier,
                      ),
                    TextInformationOfFile(
                      value: " · ",
                      style: widget.style,
                    ),
                    Flexible(
                      child: TextInformationOfFile(
                        value: widget.mimeType.getFileType(
                          context,
                          fileType: widget.fileType,
                        ),
                        style: widget.style,
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
  bool get wantKeepAlive => true;
}
