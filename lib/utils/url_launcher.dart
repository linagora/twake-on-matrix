import 'package:twake_chat/config/app_constants.dart';
import 'package:twake_chat/presentation/mixins/go_to_direct_chat_mixin.dart';
import 'package:twake_chat/presentation/model/search/presentation_search.dart';
import 'package:twake_chat/utils/extension/url_extension.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:matrix/matrix.dart';
import 'package:punycode/punycode.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/utils/adaptive_bottom_sheet.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/message_link/policy/message_link_policy.provider.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/domain/model/public_rooms/room_address.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/public_rooms/preview/public_room_preview_sheet.dart';
import 'package:twake_chat/widgets/profile_bottom_sheet.dart';
import 'platform_infos.dart';

/// Whether a message link to [targetRoomId], tapped inside the chat
/// [openRoomId], scrolls that open chat instead of navigating: navigating to
/// the URL it already shows would not notify it again.
bool jumpsInOpenChat({
  required String? openRoomId,
  required String targetRoomId,
}) => openRoomId == targetRoomId;

class UrlLauncher with GoToDraftChatMixin {
  static const _blockedSchemes = {AppConfig.appOpenUrlScheme, 'file'};

  final String? url;
  final BuildContext context;
  final Room? room;

  UrlLauncher(this.context, {this.url, this.room});

  final ChromeSafariBrowser? browser = PlatformInfos.isMobile
      ? ChromeSafariBrowser()
      : null;

  void launchUrl({bool isInvitationLink = false}) {
    if (url!.toLowerCase().startsWith(AppConfig.deepLinkPrefix) ||
        url!.toLowerCase().startsWith(AppConfig.inviteLinkPrefix) ||
        {'#', '@', '!', '+', '\$'}.contains(url![0]) ||
        url!.toLowerCase().startsWith(AppConfig.schemePrefix)) {
      return openMatrixToUrl(isInvitationLink: isInvitationLink);
    }
    final uri = Uri.tryParse(url!);
    if (uri == null) {
      // we can't open this thing
      TwakeSnackBar.show(context, L10n.of(context)!.cantOpenUri(url!));
      return;
    }
    final container = ProviderScope.containerOf(context, listen: false);
    final policy = container.read(messageLinkPolicyProvider);
    final webAppMatrixTo =
        policy.matrixToForWebLink(
          url!,
          webAppOrigin: container
              .read(loginHomeserverSummaryProvider)
              .webAppOrigin,
        ) ??
        policy.matrixToForRoomsLink(
          url!,
          isKnownRoom: (roomId) => _isOpenableRoom(
            container.read(activeMatrixClientProvider)?.getRoomById(roomId),
          ),
        );
    if (webAppMatrixTo != null) {
      return openMatrixToUrl(
        customUrl: webAppMatrixTo,
        isInvitationLink: isInvitationLink,
      );
    }
    if (uri.host == AppConstants.appLinkUniversalLinkDomain) {
      final inviteUri = Uri.parse(AppConfig.inviteLinkPrefix);
      final matrixToUri = uri.replace(
        host: inviteUri.host,
        path: uri.path.replaceFirst('/chat', ''),
      );
      return openMatrixToUrl(
        customUrl: matrixToUri.toString(),
        isInvitationLink: isInvitationLink,
      );
    }
    if (!{'https', 'http'}.contains(uri.scheme)) {
      _launchNonHttpUrl(uri);
      return;
    }
    if (uri.host.isEmpty) {
      TwakeSnackBar.show(context, L10n.of(context)!.cantOpenUri(url!));
      return;
    }
    // okay, we have either an http or an https URI.
    // As some platforms have issues with opening unicode URLs, we are going to help
    // them out by punycode-encoding them for them ourself.
    final newHost = uri.host
        .split('.')
        .map((hostPartEncoded) {
          final hostPart = Uri.decodeComponent(hostPartEncoded);
          final hostPartPunycode = punycodeEncode(hostPart);
          return hostPartPunycode != '$hostPart-'
              ? 'xn--$hostPartPunycode'
              : hostPart;
        })
        .join('.');
    // Force LaunchMode.externalApplication, otherwise url_launcher will default
    // to opening links in a webview on mobile platforms.
    launchUrlString(
      uri.replace(host: newHost).toString(),
      mode: LaunchMode.externalApplication,
    );
  }

  void _launchNonHttpUrl(Uri uri) {
    // we need to transmute geo URIs on desktop and on iOS
    if ((!PlatformInfos.isMobile || PlatformInfos.isIOS) &&
        uri.scheme == 'geo' &&
        _launchGeoUri(uri)) {
      return;
    }
    if (!uri.hasScheme || isHostAndPortUri(uri)) {
      // a network-path reference (//example.com) already has its slashes
      launchUrlString(url!.startsWith('//') ? 'https:$url' : 'https://$url');
      return;
    }
    _launchAppSchemeUrl(uri);
  }

  bool _launchGeoUri(Uri uri) {
    final latlong = uri.path
        .split(';')
        .first
        .split(',')
        .map((s) => double.tryParse(s))
        .toList();
    if (latlong.length != 2 || latlong.first == null || latlong.last == null) {
      return false;
    }
    if (PlatformInfos.isIOS) {
      // iOS is great at not following standards, so we need to transmute the geo URI
      // to an apple maps thingy
      // https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/MapLinks/MapLinks.html
      final ll = '${latlong.first},${latlong.last}';
      launchUrlString('https://maps.apple.com/?q=$ll&sll=$ll');
    } else {
      // transmute geo URIs on desktop to openstreetmap links, as those usually can't handle
      // geo URIs
      launchUrlString(
        'https://www.openstreetmap.org/?mlat=${latlong.first}&mlon=${latlong.last}#map=16/${latlong.first}/${latlong.last}',
      );
    }
    return true;
  }

  // The app's own scheme would reopen Twake with the same link, in a loop.
  // A file: link would open a local file or app on desktop.
  Future<void> _launchAppSchemeUrl(Uri uri) async {
    final launched =
        !_blockedSchemes.contains(uri.scheme) &&
        await launchUrlString(
          url!,
          mode: LaunchMode.externalApplication,
        ).catchError((_) => false);
    if (!launched && context.mounted) {
      TwakeSnackBar.show(context, L10n.of(context)!.cantOpenUri(url!));
    }
  }

  /// A room the user has joined or is invited to, as [openMatrixToUrl]
  /// opens directly.
  bool _isOpenableRoom(Room? room) =>
      room?.membership == Membership.join ||
      room?.membership == Membership.invite;

  void openMatrixToUrl({
    String? customUrl,
    bool isInvitationLink = false,
  }) async {
    final matrix = Matrix.of(context);
    final url = (customUrl ?? this.url!).replaceFirst(
      AppConfig.deepLinkPrefix,
      AppConfig.inviteLinkPrefix,
    );

    // The identifier might be a matrix.to url and needs escaping. Or, it might have multiple
    // identifiers (room id & event id), or it might also have a query part.
    // All this needs parsing.
    final identityParts =
        url.parseIdentifierIntoParts() ??
        Uri.tryParse(url)?.host.parseIdentifierIntoParts() ??
        Uri.tryParse(url)?.pathSegments
            .lastWhereOrNull((_) => true)
            ?.parseIdentifierIntoParts();
    if (identityParts == null) {
      return; // no match, nothing to do
    }
    if (identityParts.primaryIdentifier.sigil == '#' ||
        identityParts.primaryIdentifier.sigil == '!') {
      // we got a room! Let's open that one
      final roomIdOrAlias = identityParts.primaryIdentifier;
      final event = identityParts.secondaryIdentifier;
      final room =
          matrix.client.getRoomByAlias(roomIdOrAlias) ??
          matrix.client.getRoomById(roomIdOrAlias);
      final canOpenDirectly =
          room != null &&
          (room.membership == Membership.join ||
              room.membership == Membership.invite);
      if (!canOpenDirectly) {
        await showAdaptiveBottomSheet(
          context: context,
          builder: (_) => PublicRoomPreviewSheet(
            address: RoomAddress(
              roomIdOrAlias,
              via: identityParts.via.toList(),
            ),
            eventId: event,
          ),
        );
        return;
      }
      final openChat = context.findAncestorStateOfType<ChatController>();
      if (event != null &&
          jumpsInOpenChat(
            openRoomId: openChat?.roomId,
            targetRoomId: room.id,
          )) {
        await openChat!.scrollToEventIdAndHighlight(event);
        return;
      }
      RoomRoute(roomid: room.id, event: event).go(context);
    } else if (identityParts.primaryIdentifier.sigil == '@') {
      if (room?.isDirectChat == true) {
        await showAdaptiveBottomSheet(
          context: context,
          builder: (c) => ProfileBottomSheet(
            userId: identityParts.primaryIdentifier,
            outerContext: context,
          ),
        );
        return;
      }

      onContactTap(
        context: context,
        path: 'rooms',
        isInvitationLink: isInvitationLink,
        contactPresentationSearch: ContactPresentationSearch(
          matrixId: identityParts.primaryIdentifier,
          displayName:
              room
                  ?.unsafeGetUserFromMemoryOrFallback(
                    identityParts.primaryIdentifier,
                  )
                  .displayName ??
              identityParts.primaryIdentifier,
        ),
      );
    }
  }

  void openUrlInAppBrowser() async {
    if (url != null) {
      if (PlatformInfos.isMobile) {
        await browser?.open(
          url: WebUri(url!),
          settings: ChromeSafariBrowserSettings(
            shareState: CustomTabsShareState.SHARE_STATE_ON,
            barCollapsingEnabled: true,
          ),
        );
      } else {
        launchUrlString(url!);
      }
    }
  }
}
