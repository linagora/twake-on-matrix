import 'dart:typed_data';

import 'package:fluffychat/pages/chat/send_file_dialog/send_file_dialog_style.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/presentation/list_notifier.dart';
import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:fluffychat/widgets/twake_components/twake_loading/twake_loading_indicator.dart';
import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart';

class MediaPageViewWidget extends StatelessWidget {
  final ListNotifier<MatrixFile> filesNotifier;

  final Map<MatrixFile, MatrixImageFile?> thumbnails;

  const MediaPageViewWidget({
    super.key,
    required this.filesNotifier,
    required this.thumbnails,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: filesNotifier,
      builder: (context, files, _) {
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
              child: ValueListenableBuilder(
                valueListenable: filesNotifier,
                builder: (context, files, _) {
                  final firstFile = files.first;
                  if (thumbnails[firstFile] == null &&
                      firstFile.bytes == null) {
                    return const TwakeLoadingIndicator();
                  }
                  return Image.memory(
                    firstFile.bytes ??
                        thumbnails[firstFile]?.bytes ??
                        Uint8List(0),
                    fit: BoxFit.cover,
                    cacheWidth: (SendFileDialogStyle.imageSize *
                            MediaQuery.devicePixelRatioOf(context))
                        .round(),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
