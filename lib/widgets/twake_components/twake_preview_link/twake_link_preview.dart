import 'package:fluffychat/presentation/widget_keys/widget_keys.dart';
import 'package:fluffychat/pages/chat/events/formatted_text_widget.dart';
import 'package:fluffychat/presentation/mixins/linkify_mixin.dart';
import 'package:fluffychat/presentation/widget_keys/link_preview_keys.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview_item.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_view.dart';
import 'package:flutter/material.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:matrix/matrix.dart' hide Visibility;

class TwakeLinkPreview extends StatelessWidget with LinkifyMixin {
  final Event event;
  final String localizedBody;
  final bool ownMessage;
  final double fontSize;
  final TextStyle? linkStyle;
  final TextStyle? richTextStyle;
  final bool isCaption;

  const TwakeLinkPreview({
    super.key,
    required this.event,
    required this.localizedBody,
    required this.ownMessage,
    required this.fontSize,
    this.linkStyle,
    this.richTextStyle,
    this.isCaption = false,
  });

  static ValueKey<String> get twakeLinkViewKey =>
      LinkPreviewKeys.twakeLinkView.valueKey;

  static ValueKey<String> get twakeLinkPreviewItemKey =>
      LinkPreviewKeys.twakeLinkPreviewItem.valueKey;

  @override
  Widget build(BuildContext context) {
    final firstValidUrl = localizedBody.getFirstValidUrl();
    return TwakeLinkView(
      key: twakeLinkViewKey,
      firstValidUrl: firstValidUrl,
      isCaption: isCaption,
      body: event.formattedText.isNotEmpty
          ? FormattedTextWidget(
              event: event,
              linkStyle: linkStyle,
              fontSize: fontSize,
            )
          : MatrixLinkifyText(
              text: localizedBody,
              textStyle: richTextStyle,
              linkStyle: linkStyle,
              linkTypes: const [LinkType.url, LinkType.phone, LinkType.date],
              textAlign: TextAlign.start,
              onTapDownLink: (tapDownDetails, link) => handleOnTappedLinkHtml(
                context: context,
                details: tapDownDetails,
                link: link,
              ),
            ),
      previewItemWidget: TwakeLinkPreviewItem(
        key: twakeLinkPreviewItemKey,
        ownMessage: ownMessage,
        previewLink: firstValidUrl,
      ),
    );
  }
}
