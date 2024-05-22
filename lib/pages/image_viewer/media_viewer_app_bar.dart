import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/image_viewer/media_viewer_app_bar_view.dart';
import 'package:fluffychat/presentation/mixins/media_viewer_app_bar_mixin.dart';
import 'package:fluffychat/presentation/mixins/save_file_to_twake_downloads_folder_mixin.dart';
import 'package:fluffychat/presentation/mixins/save_media_to_gallery_android_mixin.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class MediaViewerAppBar extends StatefulWidget {
  const MediaViewerAppBar({
    super.key,
    this.showAppbarPreviewNotifier,
    this.event,
    this.enablePaddingAppbar = true,
  });

  final ValueNotifier<bool>? showAppbarPreviewNotifier;
  final Event? event;
  final bool? enablePaddingAppbar;

  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  @override
  State<MediaViewerAppBar> createState() => MediaViewerAppBarController();
}

class MediaViewerAppBarController extends State<MediaViewerAppBar>
    with
        SaveFileToTwakeAndroidDownloadsFolderMixin,
        SaveMediaToGalleryAndroidMixin,
        MediaViewerAppBarMixin {
  ValueNotifier<bool>? showAppbarPreview;

  @override
  void initState() {
    super.initState();
    showAppbarPreview = widget.showAppbarPreviewNotifier;
  }

  @override
  void dispose() {
    super.dispose();
    showAppbarPreview?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaViewerAppbarView(this);
  }
}
