import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/presentation/list_notifier.dart';
import 'package:fluffychat/utils/interactive_viewer_gallery.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/hero_page_route.dart';
import 'package:flutter/material.dart';
import 'send_file_dialog_style.dart';

import 'package:matrix/matrix.dart';

class MediaPageViewWidget extends StatelessWidget {
  const MediaPageViewWidget({
    super.key,
    required this.files,
  });

  final ListNotifier<MatrixFile> files;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context, rootNavigator: PlatformInfos.isWeb).push(
          HeroPageRoute(
            builder: (context) {
              return InteractiveViewerGallery(
                itemBuilder: ImageViewer(
                  imageData: files.value.first.bytes,
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
          child: files.value.first.bytes != null
              ? Image.memory(
                  files.value.first.bytes!,
                  fit: BoxFit.cover,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
