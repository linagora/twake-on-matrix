import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/int_extension.dart';
import 'package:fluffychat/widgets/file_widget/base_file_tile_widget.dart';
import 'package:fluffychat/widgets/file_widget/file_tile_widget_style.dart';
import 'package:flutter/material.dart';

class FileTileWidget extends BaseFileTileWidget {
  FileTileWidget({
    super.key,
    required super.mimeType,
    required super.filename,
    super.fileType,
    super.highlightText,
    super.sizeString,
    super.backgroundColor,
    super.fileTileIcon,
    super.imageBytes,
    super.style = const FileTileWidgetStyle(),
    super.ownMessage = false,
  }) : super(
          subTitle: (context) => Row(
            children: [
              if (sizeString != null)
                TextInformationOfFile(
                  value: sizeString,
                  style: style.textInformationStyle(context),
                ),
              TextInformationOfFile(
                value: " · ",
                style: style.textInformationStyle(context),
              ),
              Flexible(
                child: TextInformationOfFile(
                  value: mimeType.getFileType(
                    context,
                    fileType: fileType,
                  ),
                  style: style.textInformationStyle(context),
                ),
              ),
            ],
          ),
        );
}

class TextInformationOfFile extends StatelessWidget {
  final String value;
  final TextStyle? style;
  final ValueNotifier<DownloadPresentationState>? downloadFileStateNotifier;

  const TextInformationOfFile({
    super.key,
    required this.value,
    this.downloadFileStateNotifier,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (downloadFileStateNotifier != null)
          ValueListenableBuilder<DownloadPresentationState>(
            valueListenable: downloadFileStateNotifier!,
            builder: ((context, downloadFileState, child) {
              if (downloadFileState is DownloadingPresentationState &&
                  downloadFileState.total != null &&
                  downloadFileState.receive != null &&
                  downloadFileState.total! >= IntExtension.oneKB) {
                return Text(
                  '${downloadFileState.receive!.bytesToMB(placeDecimal: 1)} MB / ',
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }
              return const SizedBox.shrink();
            }),
          ),
        Text(
          value,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
