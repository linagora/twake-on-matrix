import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_view_style.dart';
import 'package:flutter/material.dart';

class TwakeLinkView extends StatelessWidget {
  final Widget body;
  final Widget previewItemWidget;
  final String? firstValidUrl;
  final bool isCaption;

  const TwakeLinkView({
    super.key,
    required this.body,
    required this.previewItemWidget,
    this.firstValidUrl,
    this.isCaption = false,
  });

  @override
  Widget build(BuildContext context) {
    if (firstValidUrl == null) {
      return _buildMessageBody(context);
    }

    return _buildMessageWithPreview(context);
  }

  Widget _buildMessageWithPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: isCaption
              ? EdgeInsets.zero
              : TwakeLinkViewStyle.previewItemPadding,
          child: previewItemWidget,
        ),
        const SizedBox(height: TwakeLinkViewStyle.previewToBodySpacing),
        _buildMessageBody(context),
      ],
    );
  }

  Widget _buildMessageBody(BuildContext context) {
    return Padding(
      padding: isCaption
          ? EdgeInsets.zero
          : TwakeLinkViewStyle.paddingMessageBody,
      child: body,
    );
  }
}
