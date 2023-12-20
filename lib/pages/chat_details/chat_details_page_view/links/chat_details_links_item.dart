import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/preview_url/get_preview_url_success.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/links/chat_details_links_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/mixins/get_preview_url_mixin.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatDetailsLinkItem extends StatefulWidget {
  const ChatDetailsLinkItem({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  State<ChatDetailsLinkItem> createState() => _ChatDetailsLinkItemState();
}

class _ChatDetailsLinkItemState extends State<ChatDetailsLinkItem>
    with GetPreviewUrlMixin {
  String get _link => widget.event.firstValidUrl ?? '';

  Uri get _uri {
    return Uri.tryParse(_link) ?? Uri();
  }

  @override
  String debugLabel = 'ChatDetailsLinkItem';

  @override
  void initState() {
    super.initState();
    getPreviewUrl(uri: _uri);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: getPreviewUrlStateNotifier,
      builder: (context, previewUrlState, child) {
        final urlPreview = previewUrlState
            .getSuccessOrNull<GetPreviewUrlSuccess>()
            ?.urlPreview;
        return InkWell(
          onTap: () => UrlLauncher(context, url: _link).launchUrl(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ChatDetailsLinksStyle.margin,
            ),
            child: Row(
              children: [
                Container(
                  width: ChatDetailsLinksStyle.avatarSize,
                  height: ChatDetailsLinksStyle.avatarSize,
                  alignment: Alignment.center,
                  decoration: ChatDetailsLinksStyle.avatarDecoration(context),
                  child: urlPreview?.imageUri != null
                      ? MxcImage(
                          uri: urlPreview!.imageUri,
                          isThumbnail: false,
                          fit: BoxFit.cover,
                          width: ChatDetailsLinksStyle.avatarSize,
                          height: ChatDetailsLinksStyle.avatarSize,
                          placeholder: (_) => child!,
                        )
                      : child!,
                ),
                const SizedBox(
                  width: ChatDetailsLinksStyle.margin,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        urlPreview?.title ?? _link,
                        maxLines: 2,
                        style: ChatDetailsLinksStyle.titleTextStyle(context),
                      ),
                      if (urlPreview?.description != null)
                        Text(
                          urlPreview!.description!,
                          maxLines: 2,
                          style: ChatDetailsLinksStyle.descriptionTextStyle(
                            context,
                          ),
                        ),
                      Text(
                        _link,
                        maxLines: 2,
                        style: ChatDetailsLinksStyle.linkTextStyle(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: _AvatarPlaceholder(uri: _uri),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({
    required this.uri,
  });

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Text(
      uri.host.getShortcutNameForAvatar(),
      style: ChatDetailsLinksStyle.avatarTextStyle(context),
    );
  }
}
