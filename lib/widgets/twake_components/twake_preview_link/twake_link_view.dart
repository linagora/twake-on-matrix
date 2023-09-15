import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/preview_url/get_preview_url_success.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/presentation/extensions/media/url_preview_extension.dart';
import 'package:fluffychat/widgets/clean_rich_text.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_view_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix_link_text/link_text.dart';

class TwakeLinkView extends StatelessWidget {
  final String text;
  final Widget childWidget;
  final bool ownMessage;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;
  final TextAlign? textAlign;
  final LinkTapHandler? onLinkTap;
  final int? maxLines;
  final String? firstValidUrl;
  final TextSpanBuilder? textSpanBuilder;
  final ValueNotifier<Either<Failure, Success>> getPreviewUrlStateNotifier;

  const TwakeLinkView({
    Key? key,
    required this.text,
    required this.childWidget,
    required this.ownMessage,
    required this.getPreviewUrlStateNotifier,
    this.textStyle,
    this.linkStyle,
    this.textAlign = TextAlign.start,
    this.onLinkTap,
    this.maxLines,
    this.firstValidUrl,
    this.textSpanBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (firstValidUrl == null) {
      return _buildWidgetNoPreview(context);
    }

    return _buildWidgetWithPreview(context, firstValidUrl!);
  }

  Widget _buildWidgetWithPreview(BuildContext context, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder(
          valueListenable: getPreviewUrlStateNotifier,
          builder: (context, state, _) {
            return state.fold(
              (failure) => const SizedBox.shrink(),
              (success) {
                if (success is GetPreviewUrlSuccess) {
                  final previewLink = success.urlPreview.toPresentation();
                  return Container(
                    width: double.infinity,
                    decoration: ShapeDecoration(
                      color: ownMessage
                          ? LinagoraRefColors.material().primary[95]
                          : LinagoraStateLayer(
                              LinagoraSysColors.material().surfaceTint,
                            ).opacityLayer1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          TwakeLinkViewStyle.radiusBorder,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (previewLink.imageUri != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(
                                TwakeLinkViewStyle.radiusBorder,
                              ),
                              topRight: Radius.circular(
                                TwakeLinkViewStyle.radiusBorder,
                              ),
                            ),
                            child: MxcImage(
                              width: MessageStyle.messageBubbleWidth(context),
                              uri: previewLink.imageUri,
                              fit: BoxFit.contain,
                              isThumbnail: false,
                            ),
                          ),
                        if (previewLink.title != null)
                          Padding(
                            padding: TwakeLinkViewStyle.paddingAll,
                            child: Text(
                              previewLink.title!,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        if (previewLink.description != null)
                          Padding(
                            padding: TwakeLinkViewStyle.paddingAll,
                            child: Text(
                              previewLink.description!,
                              style: textStyle,
                            ),
                          ),
                      ],
                    ),
                  );
                }
                return const SizedBox();
              },
            );
          },
        ),
        const SizedBox(height: 2),
        _buildCleanRichText(context)
      ],
    );
  }

  Widget _buildWidgetNoPreview(BuildContext context) {
    return Padding(
      padding: TwakeLinkViewStyle.paddingWidgetNoPreview,
      child: _buildCleanRichText(context),
    );
  }

  Widget _buildCleanRichText(BuildContext context) {
    return Padding(
      padding: TwakeLinkViewStyle.paddingCleanRichText,
      child: TwakeCleanRichText(
        text: text,
        childWidget: childWidget,
        textStyle: textStyle,
        linkStyle: linkStyle,
        textAlign: textAlign ?? TextAlign.start,
        onLinkTap: onLinkTap,
        maxLines: maxLines,
        textSpanBuilder: textSpanBuilder,
      ),
    );
  }
}
