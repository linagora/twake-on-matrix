import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_view_style.dart';
import 'package:flutter/material.dart';

class TwakeLinkView extends StatelessWidget {
  final Widget body;
  final Widget previewItemWidget;
  final String? firstValidUrl;

  const TwakeLinkView({
    super.key,
    required this.body,
    required this.previewItemWidget,
    this.firstValidUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (firstValidUrl == null) {
      return _buildMessageBody();
    }

    return _buildMessageWithPreview(context);
  }

  Widget _buildMessageWithPreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: TwakeLinkViewStyle.previewItemPadding,
          child: previewItemWidget,
        ),
        const SizedBox(height: TwakeLinkViewStyle.previewToBodySpacing),
        _buildMessageBody(),
      ],
    );
  }

  Widget _buildMessageBody() {
    return Padding(
      padding: TwakeLinkViewStyle.paddingMessageBody,
      child: body,
    );
  }
}
