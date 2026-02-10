import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/events/download_video_widget.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/pages/image_viewer/media_viewer_app_bar.dart';
import 'package:fluffychat/pages/media_viewer/media_viewer.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class MediaViewerView extends StatelessWidget {
  const MediaViewerView({super.key, required this.controller});

  final MediaViewerController controller;

  @override
  Widget build(BuildContext context) {
    final pageView = PageView.builder(
      controller: controller.pageController,
      physics: controller.scrollPhysics,
      onPageChanged: (value) {
        controller.currentPage.value = value;
      },
      itemCount: controller.mediaEvents.length,
      itemBuilder: (context, index) {
        final event = controller.mediaEvents[index];
        if (event.messageType == MessageTypes.Image) {
          return ImageViewer(
            event: event,
            showAppBar: false,
            onZoomChanged: controller.togglePageViewScroll,
          );
        }

        if (event.messageType == MessageTypes.Video) {
          return DownloadVideoWidget(event: event, showAppBar: false);
        }

        if (event.type == EventTypes.Encrypted) {
          return Center(child: Text(L10n.of(context)!.encrypted));
        }

        return const SizedBox();
      },
    );

    final appBar = ValueListenableBuilder(
      valueListenable: controller.showAppBarAndPreview,
      builder: (context, show, child) {
        if (!show) return const SizedBox();

        return child ?? const SizedBox();
      },
      child: ValueListenableBuilder(
        valueListenable: controller.currentPage,
        builder: (context, page, child) {
          if (page == -1) return const SizedBox();

          return Material(
            type: MaterialType.transparency,
            child: MediaViewerAppBar(event: controller.mediaEvents[page]),
          );
        },
      ),
    );

    final toggleAppBarAndPreviewOverlay = ValueListenableBuilder(
      valueListenable: controller.currentPage,
      builder: (context, page, child) {
        if (page == -1) return const SizedBox();

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: controller.mediaEvents[page].messageType == MessageTypes.Video
              ? null
              : controller.showAppBarAndPreview.toggle,
        );
      },
    );

    final previewer = ValueListenableBuilder(
      valueListenable: controller.showAppBarAndPreview,
      builder: (context, show, child) {
        return IgnorePointer(
          ignoring: !show,
          child: Opacity(opacity: show ? 1 : 0, child: child),
        );
      },
      child: SizedBox(
        height: 46,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: controller.mediaEvents.length,
          separatorBuilder: (_, __) => const SizedBox(width: 2),
          itemBuilder: (context, index) {
            return ValueListenableBuilder(
              valueListenable: controller.currentPage,
              builder: (context, page, child) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: page == index
                          ? LinagoraSysColors.material().primary
                          : LinagoraSysColors.material().onPrimary,
                      width: 2,
                    ),
                  ),
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: () {
                  controller.pageController.jumpToPage(index);
                },
                child: Container(
                  width: 44,
                  padding: const EdgeInsets.all(2),
                  child: MxcImage(
                    key: ValueKey(controller.mediaEvents[index].eventId),
                    event: controller.mediaEvents[index],
                    fit: BoxFit.cover,
                    enableHeroAnimation: false,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    return Stack(
      children: [
        pageView,
        Positioned.fill(child: toggleAppBarAndPreviewOverlay),
        appBar,
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(child: previewer),
        ),
      ],
    );
  }
}
