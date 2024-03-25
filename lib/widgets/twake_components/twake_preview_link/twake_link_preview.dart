import 'package:fluffychat/domain/app_state/preview_url/get_preview_url_success.dart';
import 'package:fluffychat/presentation/extensions/media/url_preview_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/mixins/get_preview_url_mixin.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview_item.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview_item_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_view.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix_link_text/link_text.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TwakeLinkPreview extends StatefulWidget {
  final Uri uri;
  final int? preferredPointInTime;
  final String text;
  final Widget messageContentWidget;
  final bool ownMessage;

  const TwakeLinkPreview({
    super.key,
    required this.uri,
    this.preferredPointInTime,
    required this.text,
    required this.messageContentWidget,
    required this.ownMessage,
  });

  @override
  State<TwakeLinkPreview> createState() => TwakeLinkPreviewController();
}

class TwakeLinkPreviewController extends State<TwakeLinkPreview>
    with GetPreviewUrlMixin {
  String? get firstValidUrl => widget.text.getFirstValidUrl();

  static const twakeLinkViewKey = ValueKey('TwakeLinkPreviewKey');

  static const twakeLinkPreviewItemKey = ValueKey('TwakeLinkPreviewItemKey');

  @override
  String debugLabel = 'TwakeLinkPreviewController';

  @override
  void initState() {
    if (firstValidUrl != null) {
      getPreviewUrl(uri: widget.uri);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TwakeLinkView(
      key: twakeLinkViewKey,
      text: widget.text,
      firstValidUrl: firstValidUrl,
      messageContentWidget: widget.messageContentWidget,
      previewItemWidget: ValueListenableBuilder(
        valueListenable: getPreviewUrlStateNotifier,
        builder: (context, state, child) {
          return state.fold(
            (failure) => const SizedBox.shrink(),
            (success) {
              if (success is GetPreviewUrlSuccess) {
                final previewLink = success.urlPreview.toPresentation();
                return TwakeLinkPreviewItem(
                  key: twakeLinkPreviewItemKey,
                  ownMessage: widget.ownMessage,
                  urlPreviewPresentation: previewLink,
                  previewLink: firstValidUrl,
                );
              }
              return child!;
            },
          );
        },
        child: Skeletonizer.zone(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: double.infinity,
            ),
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
                    top: Radius.circular(
                      TwakeLinkPreviewItemStyle.radiusBorder,
                    ),
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
      ),
    );
  }
}
