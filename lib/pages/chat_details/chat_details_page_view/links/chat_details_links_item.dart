import 'package:twake_chat/pages/chat_details/chat_details_page_view/links/chat_details_links_style.dart';
import 'package:twake_chat/providers/url_preview_provider.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:twake_chat/utils/string_extension.dart';
import 'package:twake_chat/utils/url_launcher.dart';
import 'package:twake_chat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';

class ChatDetailsLinkItem extends ConsumerWidget {
  const ChatDetailsLinkItem({super.key, required this.event});

  final Event event;

  String get _link => event.firstValidUrl ?? '';

  Uri get _uri {
    return Uri.tryParse(_link) ?? Uri();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlPreview = ref.watch(urlPreviewProvider(_uri)).value;
    final placeholder = _AvatarPlaceholder(uri: _uri);
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
                      placeholder: (_) => placeholder,
                    )
                  : placeholder,
            ),
            const SizedBox(width: ChatDetailsLinksStyle.margin),
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
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Text(
      uri.host.getShortcutNameForAvatar(),
      style: ChatDetailsLinksStyle.avatarTextStyle(context),
    );
  }
}
