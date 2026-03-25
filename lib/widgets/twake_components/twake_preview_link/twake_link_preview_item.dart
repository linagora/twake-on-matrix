import 'package:fluffychat/domain/app_state/preview_url/get_preview_url_success.dart';
import 'package:fluffychat/presentation/extensions/media/url_preview_extension.dart';
import 'package:fluffychat/presentation/model/media/url_preview_presentation.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/mixins/get_preview_url_mixin.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview_item_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TwakeLinkPreviewItem extends StatefulWidget {
  final bool ownMessage;
  final String? previewLink;

  const TwakeLinkPreviewItem({
    super.key,
    required this.ownMessage,
    this.previewLink,
  });

  static const linkPreviewBodyKey = ValueKey('TwakeLinkPreviewBodyKey');

  static const linkPreviewLargeKey = ValueKey('LinkPreviewLargeKey');

  @override
  State<TwakeLinkPreviewItem> createState() => _TwakeLinkPreviewItemState();
}

class _TwakeLinkPreviewItemState extends State<TwakeLinkPreviewItem>
    with AutomaticKeepAliveClientMixin, GetPreviewUrlMixin {
  void _getPreviewInfo() {
    if (widget.previewLink == null || widget.previewLink!.trim().isEmpty) {
      return;
    }
    final uri = Uri.tryParse(widget.previewLink!);
    if (uri == null) return;
    getPreviewUrl(uri: uri);
  }

  @override
  void initState() {
    super.initState();
    _getPreviewInfo();
  }

  @override
  void didUpdateWidget(covariant TwakeLinkPreviewItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewLink != widget.previewLink) {
      _getPreviewInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ValueListenableBuilder(
      valueListenable: getPreviewUrlStateNotifier,
      builder: (context, state, child) {
        return state.fold((failure) => const SizedBox.shrink(), (success) {
          if (success is GetPreviewUrlSuccess) {
            final previewPresentation = success.urlPreview.toPresentation();
            return Container(
              key: TwakeLinkPreviewItem.linkPreviewBodyKey,
              constraints: const BoxConstraints(minWidth: double.infinity),
              height: TwakeLinkPreviewItemStyle.maxHeightPreviewItem,
              decoration: ShapeDecoration(
                color: widget.ownMessage
                    ? LinagoraSysColors.material().primaryContainer
                    : LinagoraSysColors.material().onSurface.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    TwakeLinkPreviewItemStyle.radiusBorder,
                  ),
                ),
              ),
              child: LinkPreviewBuilder(
                key: TwakeLinkPreviewItem.linkPreviewLargeKey,
                urlPreviewPresentation: previewPresentation,
                previewLink: widget.previewLink,
              ),
            );
          }
          return child!;
        });
      },
      child: Skeletonizer.zone(
        child: Container(
          constraints: const BoxConstraints(minWidth: double.infinity),
          height: TwakeLinkPreviewItemStyle.maxHeightPreviewItem,
          decoration: ShapeDecoration(
            color: widget.ownMessage
                ? LinagoraRefColors.material().primary[95]
                : LinagoraStateLayer(
                    LinagoraSysColors.material().surfaceTint,
                  ).opacityLayer1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                TwakeLinkPreviewItemStyle.radiusBorder,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Bone.button(
                width: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
                height: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
                  bottom: Radius.circular(
                    TwakeLinkPreviewItemStyle.radiusBorder,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      key: LinkPreviewBuilder.paddingTitleKey,
                      padding: TwakeLinkPreviewItemStyle.paddingTitle,
                      child: Column(
                        children: [
                          Bone.text(
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TwakeLinkPreviewItemStyle.skeletonizerTextPadding,
                          Bone.text(
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      key: LinkPreviewBuilder.paddingSubtitleKey,
                      padding: TwakeLinkPreviewItemStyle.paddingSubtitle,
                      child: Column(
                        children: [
                          Bone.text(
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TwakeLinkPreviewItemStyle.skeletonizerTextPadding,
                          Bone.text(
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  String debugLabel = 'TwakeLinkPreviewItem';
}

class LinkPreviewBuilder extends StatelessWidget {
  const LinkPreviewBuilder({
    super.key,
    required this.urlPreviewPresentation,
    this.previewLink,
  });

  final String? previewLink;

  final UrlPreviewPresentation urlPreviewPresentation;

  static const clipRRectKey = ValueKey('ClipRRectKey');

  static const mxcImageKey = ValueKey('MxcImageKey');

  static const paddingTitleKey = ValueKey('PaddingTitleKey');

  static const paddingSubtitleKey = ValueKey('PaddingSubtitleKey');

  static const titleKey = ValueKey('TextTitleKey');

  static const subtitleKey = ValueKey('TextSubtitleKey');

  static const imageDefaultKey = ValueKey('ImageDefaultKey');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (previewLink == null) return;
        UrlLauncher(context, url: previewLink).launchUrl();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            key: LinkPreviewBuilder.clipRRectKey,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
              bottom: Radius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
            ),
            child: SizedBox(
              width: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
              height: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
              child:
                  (urlPreviewPresentation.imageUri != null &&
                      urlPreviewPresentation.imageWidth != null &&
                      urlPreviewPresentation.imageHeight != null)
                  ? MxcImage(
                      key: LinkPreviewBuilder.mxcImageKey,
                      uri: urlPreviewPresentation.imageUri,
                      height: MediaQuery.sizeOf(context).height,
                      width: MediaQuery.sizeOf(context).width,
                      fit: BoxFit.cover,
                      isThumbnail: false,
                      placeholder: (_) => const Skeletonizer.zone(
                        child: Bone.button(
                          width:
                              TwakeLinkPreviewItemStyle.heightMxcImagePreview,
                          height:
                              TwakeLinkPreviewItemStyle.heightMxcImagePreview,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(
                              TwakeLinkPreviewItemStyle.radiusBorder,
                            ),
                            bottom: Radius.circular(
                              TwakeLinkPreviewItemStyle.radiusBorder,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(
                      key: LinkPreviewBuilder.imageDefaultKey,
                      height: TwakeLinkPreviewItemStyle.heightMxcImagePreview,
                      child: Icon(
                        Icons.link,
                        size: TwakeLinkPreviewItemStyle.linkIconSize,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  key: LinkPreviewBuilder.paddingTitleKey,
                  padding: TwakeLinkPreviewItemStyle.paddingTitle,
                  child: Text(
                    key: LinkPreviewBuilder.titleKey,
                    urlPreviewPresentation.title ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  key: LinkPreviewBuilder.paddingSubtitleKey,
                  padding: TwakeLinkPreviewItemStyle.paddingSubtitle,
                  child: Text(
                    key: LinkPreviewBuilder.subtitleKey,
                    urlPreviewPresentation.description ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LinagoraRefColors.material().neutral[50],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
