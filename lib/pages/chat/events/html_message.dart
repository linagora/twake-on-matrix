import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/domain/model/extensions/string_extension.dart';
import 'package:fluffychat/pages/image_viewer/image_viewer.dart';
import 'package:fluffychat/presentation/mixins/linkify_mixin.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/mentioned_user.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/presentation/extensions/send_file_extension.dart';

import 'package:fluffychat/widgets/matrix.dart';

class HtmlMessage extends StatelessWidget with LinkifyMixin {
  final String html;
  final int? maxLines;
  final Room room;
  final TextStyle? defaultTextStyle;
  final TextStyle? linkStyle;
  final double? emoteSize;
  final Widget? bottomWidgetSpan;

  HtmlMessage({
    super.key,
    required this.html,
    this.maxLines,
    required this.room,
    this.defaultTextStyle,
    this.linkStyle,
    this.emoteSize,
    this.bottomWidgetSpan,
  });

  @override
  Widget build(BuildContext context) {
    // riot-web is notorious for creating bad reply fallback events from invalid messages which, if
    // not handled properly, can lead to impersination. As such, we strip the entire `<mx-reply>` tags
    // here already, to prevent that from happening.
    // We do *not* do this in an AST and just with simple regex here, as riot-web tends to create
    // miss-matching tags, and this way we actually correctly identify what we want to strip and, well,
    // strip it.
    final renderHtml = html.replaceAll(
      RegExp(
        '<mx-reply>.*</mx-reply>',
        caseSensitive: false,
        multiLine: false,
        dotAll: true,
      ),
      '',
    );

    // there is no need to pre-validate the html, as we validate it while rendering

    final matrix = Matrix.of(context);

    final themeData = Theme.of(context);
    return Html(
      data: renderHtml,
      defaultTextStyle: defaultTextStyle,
      emoteSize: emoteSize,
      inlineSpanEnd: bottomWidgetSpan != null
          ? WidgetSpan(child: bottomWidgetSpan!)
          : null,
      linkStyle: linkStyle ??
          themeData.textTheme.bodyMedium!.copyWith(
            color: themeData.colorScheme.secondary,
            decoration: TextDecoration.underline,
            decorationColor: themeData.colorScheme.secondary,
          ),
      linkTypes: const [
        LinkType.url,
        LinkType.phone,
      ],
      shrinkToFit: true,
      maxLines: maxLines,
      onTapDownLink: (tapDownDetails, link) => handleOnTappedLinkHtml(
        context: context,
        details: tapDownDetails,
        link: link,
      ),
      onPillTap: !room.isDirectChat
          ? (url) {
              UrlLauncher(context, url: url, room: room).launchUrl();
            }
          : null,
      getMxcUrl: (
        String mxc,
        double? width,
        double? height, {
        bool? animated = false,
      }) {
        final ratio = MediaQuery.devicePixelRatioOf(context);
        return Uri.parse(mxc)
            .getThumbnail(
              matrix.client,
              width: (width ?? 800) * ratio,
              height: (height ?? 800) * ratio,
              method: ThumbnailMethod.scale,
              animated: AppConfig.autoplayImages ? animated : false,
            )
            .toString();
      },
      onImageTap: (String mxc) => showDialog(
        context: context,
        useRootNavigator: false,
        builder: (_) => ImageViewer(
          event: Event(
            type: EventTypes.Message,
            content: <String, dynamic>{
              'body': mxc,
              'url': mxc,
              'msgtype': MessageTypes.Image,
            },
            senderId: room.client.userID!,
            originServerTs: DateTime.now(),
            eventId: 'fake_event',
            room: room,
          ),
        ),
      ),
      setCodeLanguage: (String key, String value) async {
        await matrix.store.setItem('${SettingKeys.codeLanguage}.$key', value);
      },
      getCodeLanguage: (String key) async {
        return await matrix.store.getItem('${SettingKeys.codeLanguage}.$key');
      },
      getPillInfo: !room.isDirectChat
          ? (String url) async {
              final identityParts = url.parseIdentifierIntoParts();
              final identifier = identityParts?.primaryIdentifier;
              if (identifier == null) {
                return {};
              }
              if (identifier.sigil == '@') {
                // we have a user pill
                final user = room.getState('m.room.member', identifier);
                if (user != null) {
                  return user.content;
                }
                // there might still be a profile...
                final profile =
                    await room.client.getProfileFromUserId(identifier);
                return {
                  'displayname': profile.displayName,
                  'avatar_url': profile.avatarUrl.toString(),
                };
              }
              if (identifier.sigil == '#') {
                // we have an alias pill
                for (final r in room.client.rooms) {
                  final state = r.getState('m.room.canonical_alias');
                  final altAliases = state?.content['alt_aliases'];
                  if (state != null &&
                      ((state.content['alias'] is String &&
                              state.content['alias'] == identifier) ||
                          (altAliases is List &&
                              altAliases.contains(identifier)))) {
                    // we have a room!
                    return {
                      'displayname': r.getLocalizedDisplayname(
                        MatrixLocals(L10n.of(context)!),
                      ),
                      'avatar_url': r.getState('m.room.avatar')?.content['url'],
                    };
                  }
                }
                return {};
              }
              if (identifier.sigil == '!') {
                // we have a room ID pill
                final r = room.client.getRoomById(identifier);
                if (r == null) {
                  return {};
                }
                return {
                  'displayname': r
                      .getLocalizedDisplayname(MatrixLocals(L10n.of(context)!)),
                  'avatar_url': r.getState('m.room.avatar')?.content['url'],
                };
              }
              return {};
            }
          : null,
      pillBuilder: (identifier, url, onTap, getMxcUrl) {
        final user = room.getUser(identifier);
        final displayName = user?.displayName ?? identifier;
        return MentionedUser(
          displayName:
              !room.isDirectChat ? displayName.displayMentioned : displayName,
          url: url,
          onTap: !room.isDirectChat ? onTap : null,
          textStyle: !room.isDirectChat
              ? defaultTextStyle?.copyWith(
                  color: themeData.colorScheme.primary,
                )
              : Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
        );
      },
    );
  }
}
