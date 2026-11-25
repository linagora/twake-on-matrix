import 'package:collection/collection.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/domain/model/extensions/string_extension.dart';
import 'package:twake_chat/pages/image_viewer/image_viewer.dart';
import 'package:twake_chat/pages/contacts_tab/providers/unified_contact_read_providers.dart';
import 'package:twake_chat/presentation/mixins/linkify_mixin.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:twake_chat/utils/string_extension.dart';
import 'package:twake_chat/utils/url_launcher.dart';
import 'package:twake_chat/widgets/mentioned_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/presentation/extensions/send_file_extension.dart';

import 'package:twake_chat/widgets/matrix.dart';

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
    final renderHtml = html.removeReplyFallback();

    // there is no need to pre-validate the html, as we validate it while rendering

    final matrix = Matrix.of(context);

    final themeData = Theme.of(context);

    // `Html` renders through raw `RichText`, which (unlike `Text`/`Text.rich`)
    // does not merge the ambient `DefaultTextStyle`. We merge it in here so the
    // app font family is preserved for styles that don't specify one — the
    // design-system type-scale tokens intentionally carry no `fontFamily`.
    final ambientStyle = DefaultTextStyle.of(context).style;
    final effectiveDefaultTextStyle = ambientStyle.merge(defaultTextStyle);
    final effectiveLinkStyle = ambientStyle.merge(
      linkStyle ??
          themeData
              .extension<LinagoraTextThemeExtension>()!
              .bodyMedium4
              .copyWith(
                color: themeData.colorScheme.secondary,
                decoration: TextDecoration.underline,
                decorationColor: themeData.colorScheme.secondary,
              ),
    );
    return Html(
      data: renderHtml,
      defaultTextStyle: effectiveDefaultTextStyle,
      emoteSize: emoteSize,
      inlineSpanEnd: bottomWidgetSpan != null
          ? WidgetSpan(child: bottomWidgetSpan!)
          : null,
      linkStyle: effectiveLinkStyle,
      linkTypes: const [LinkType.url, LinkType.phone],
      shrinkToFit: true,
      maxLines: maxLines,
      onTapDownLink: (tapDownDetails, link) => handleOnTappedLinkHtml(
        context: context,
        details: tapDownDetails,
        link: link,
      ),
      linkBuilder: (url, childrenSpan, linkStyle) => filenameLinkAsPlainText(
        url: url,
        childrenSpan: childrenSpan,
        linkStyle: linkStyle,
        textStyle: effectiveDefaultTextStyle,
      ),
      onPillTap: !room.isDirectChat
          ? (url) {
              UrlLauncher(context, url: url, room: room).launchUrl();
            }
          : null,
      getMxcUrl:
          (
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
                final contact = await ProviderScope.containerOf(
                  context,
                  listen: false,
                ).read(contactDisplayProvider(identifier).future);
                return {
                  'displayname': contact.resolvedDisplayName,
                  'avatar_url': contact.avatarUrl ?? '',
                };
              }
              final pillRoom = _pillRoom(identifier);
              if (pillRoom == null) {
                return {};
              }
              return {
                'displayname': pillRoom.getLocalizedDisplayname(
                  MatrixLocals(L10n.of(context)!),
                ),
                'avatar_url': pillRoom
                    .getState('m.room.avatar')
                    ?.content['url'],
              };
            }
          : null,
      pillBuilder: (identifier, url, onTap, getMxcUrl) {
        final pillRoom = _pillRoom(identifier);
        final displayName =
            pillRoom?.getLocalizedDisplayname(
              MatrixLocals(L10n.of(context)!),
            ) ??
            room.getUser(identifier)?.displayName ??
            identifier;
        // A room is named as it is; only a user gets the « @[ ] » mention.
        return MentionedUser(
          displayName: !room.isDirectChat && pillRoom == null
              ? displayName.displayMentioned
              : displayName,
          url: url,
          onTap: !room.isDirectChat ? onTap : null,
          textStyle: !room.isDirectChat
              ? defaultTextStyle?.copyWith(color: themeData.colorScheme.primary)
              : defaultTextStyle?.copyWith(
                  color: themeData.colorScheme.onSurface,
                ),
        );
      },
    );
  }

  /// The room a `!id` or `#alias` pill points at, when the user is in it.
  Room? _pillRoom(String identifier) => switch (identifier.sigil) {
    '!' => room.client.getRoomById(identifier),
    '#' => room.client.rooms.firstWhereOrNull(
      (candidate) => _hasAlias(candidate, identifier),
    ),
    _ => null,
  };

  static bool _hasAlias(Room candidate, String alias) {
    final content = candidate.getState('m.room.canonical_alias')?.content;
    final altAliases = content?['alt_aliases'];
    return content?['alias'] == alias ||
        (altAliases is List && altAliases.contains(alias));
  }
}
