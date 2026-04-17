import 'dart:async';

import 'package:fluffychat/config/first_column_inner_routes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/add_story/add_story.dart';
import 'package:fluffychat/pages/archive/archive.dart';
import 'package:fluffychat/pages/auto_homeserver_picker/auto_homeserver_picker.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_events_argument.dart';
import 'package:fluffychat/pages/chat/chat_pinned_events/pinned_messages.dart';
import 'package:fluffychat/pages/chat_adaptive_scaffold/chat_adaptive_scaffold.dart';
import 'package:fluffychat/pages/chat_blank/chat_blank.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_adaptive_scaffold.dart';
import 'package:fluffychat/pages/chat_encryption_settings/chat_encryption_settings.dart';
import 'package:fluffychat/pages/connect/connect_page.dart';
import 'package:fluffychat/pages/device_settings/device_settings.dart';
import 'package:fluffychat/pages/error_page/error_page.dart';
import 'package:fluffychat/pages/invitation_link_web/invitation_link_web.dart';
import 'package:fluffychat/pages/forward/forward.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection.dart';
import 'package:fluffychat/pages/login/login.dart';
import 'package:fluffychat/pages/login/on_auth_redirect.dart';
import 'package:fluffychat/pages/new_group/new_group.dart';
import 'package:fluffychat/pages/new_group/new_group_chat_info.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat.dart';
import 'package:fluffychat/pages/personal_qr/personal_qr.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_3pid/settings_3pid.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_app_language/settings_app_language.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_blocked_users/settings_blocked_user.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_chat/settings_chat.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_contacts_visibility/settings_contacts_visibility.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_emotes/settings_emotes.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_data_and_storage/settings_data_and_storage.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_notifications/settings_notifications.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_security/settings_security.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_stories/settings_stories.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_style/settings_style.dart';
import 'package:fluffychat/pages/share/share.dart';
import 'package:fluffychat/pages/sign_up/signup.dart';
import 'package:fluffychat/pages/splash/splash.dart';
import 'package:fluffychat/pages/story/story_page.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome.dart';
import 'package:fluffychat/presentation/model/chat/chat_router_input_argument.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/forward/forward_argument.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/app_adaptive_scaffold.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/app_adaptive_scaffold_body.dart';
import 'package:fluffychat/widgets/layouts/agruments/app_adaptive_scaffold_body_args.dart';
import 'package:fluffychat/widgets/log_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

part 'app_routes.g.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ResponsiveUtils get _responsive => getIt.get<ResponsiveUtils>();

FutureOr<String?> _loggedInRedirect(
  BuildContext context,
  GoRouterState state,
) => Matrix.of(context).client.isLogged() ? const RoomsRoute().location : null;

FutureOr<String?> _loggedOutRedirect(
  BuildContext context,
  GoRouterState state,
) => Matrix.of(context).client.isLogged()
    ? null
    : const HomeTwakeWelcomeRoute().location;

Page<void> _defaultPage(BuildContext context, Widget child, {String? name}) =>
    CustomTransitionPage(
      name: name,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          !_responsive.isMobile(context)
          ? FadeTransition(opacity: animation, child: child)
          : CupertinoPageTransition(
              primaryRouteAnimation: animation,
              secondaryRouteAnimation: secondaryAnimation,
              linearTransition: false,
              child: child,
            ),
    );

// ===========================================================================
// Top-level routes
// ===========================================================================

@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const Splash());
}

@TypedGoRoute<RootRoute>(path: '/')
class RootRoute extends GoRouteData with $RootRoute {
  const RootRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      Matrix.of(context).client.isLogged()
      ? const RoomsRoute().location
      : const HomeRoute().location;

  // Never displayed — always redirects.
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SizedBox.shrink();
}

@TypedGoRoute<HomeRoute>(
  path: '/home',
  routes: [
    TypedGoRoute<HomeLoginRoute>(path: 'login'),
    TypedGoRoute<HomeTwakeWelcomeRoute>(path: 'twakeWelcome'),
    TypedGoRoute<HomeHomeserverPickerRoute>(path: 'homeserverpicker'),
  ],
)
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute({this.$extra});
  final bool? $extra;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedInRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(
        context,
        PlatformInfos.isMobile
            ? const TwakeWelcome()
            : AutoHomeserverPicker(loggedOut: $extra),
      );
}

class HomeLoginRoute extends GoRouteData with $HomeLoginRoute {
  const HomeLoginRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedInRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const Login());
}

class HomeTwakeWelcomeRoute extends GoRouteData with $HomeTwakeWelcomeRoute {
  const HomeTwakeWelcomeRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedInRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const TwakeWelcome());
}

class HomeHomeserverPickerRoute extends GoRouteData
    with $HomeHomeserverPickerRoute {
  const HomeHomeserverPickerRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedInRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(
        context,
        const HomeserverPicker(
          arg: HomeserverPickerArg(type: HomeserverPickerType.singleAccount),
        ),
      );
}

@TypedGoRoute<OnAuthRedirectRoute>(path: '/onAuthRedirect')
class OnAuthRedirectRoute extends GoRouteData with $OnAuthRedirectRoute {
  const OnAuthRedirectRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const OnAuthRedirect());
}

@TypedGoRoute<ConnectRoute>(path: '/connect')
class ConnectRoute extends GoRouteData with $ConnectRoute {
  const ConnectRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const ConnectPage());
}

@TypedGoRoute<SignupRoute>(path: '/signup')
class SignupRoute extends GoRouteData with $SignupRoute {
  const SignupRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const SignupPage());
}

@TypedGoRoute<LogsRoute>(path: '/logs')
class LogsRoute extends GoRouteData with $LogsRoute {
  const LogsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const LogViewer());
}

@TypedGoRoute<ErrorRoute>(path: '/error')
class ErrorRoute extends GoRouteData with $ErrorRoute {
  const ErrorRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const ErrorPage());
}

@TypedGoRoute<InvitationLinkWebRoute>(path: '/chat/:matrixid')
class InvitationLinkWebRoute extends GoRouteData with $InvitationLinkWebRoute {
  const InvitationLinkWebRoute({required this.matrixid});
  final String matrixid;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, InvitationLinkWeb(matrixId: matrixid));
}

// ===========================================================================
// Rooms shell + sub-routes
// ===========================================================================

@TypedShellRoute<RoomsShellRoute>(
  routes: [
    TypedGoRoute<RoomsRoute>(
      path: '/rooms',
      routes: [
        TypedGoRoute<StoriesCreateRoute>(path: 'stories/create'),
        TypedGoRoute<StoryRoute>(
          path: 'stories/:roomid',
          routes: [TypedGoRoute<StoryShareRoute>(path: 'share')],
        ),
        TypedGoRoute<ArchiveRoute>(
          path: 'archive',
          routes: [TypedGoRoute<ArchiveRoomRoute>(path: ':roomid')],
        ),
        // Always include newprivatechat in the route tree.
        // The conditional (mobile-only first-column) is handled in redirect.
        TypedGoRoute<NewPrivateChatRoute>(
          path: 'newprivatechat',
          routes: [
            TypedGoRoute<NewPrivateChatNewGroupRoute>(
              path: 'newgroup',
              routes: [
                TypedGoRoute<NewPrivateChatNewGroupInfoRoute>(
                  path: 'newgroupinfo',
                ),
              ],
            ),
          ],
        ),
        TypedGoRoute<NewGroupRoute>(path: 'newgroup'),
        TypedGoRoute<DraftChatRoute>(path: 'draftChat'),
        TypedGoRoute<ForwardRoute>(path: 'forward'),
        TypedGoRoute<ShareRoute>(path: 'share'),
        TypedGoRoute<ProfileRoute>(
          path: 'profile',
          routes: [TypedGoRoute<ProfileQrRoute>(path: 'qr')],
        ),
        TypedGoRoute<NotificationsRoute>(path: 'notifications'),
        TypedGoRoute<StyleRoute>(path: 'style'),
        TypedGoRoute<DevicesRoute>(path: 'devices'),
        TypedGoRoute<AppLanguageRoute>(path: 'appLanguage'),
        TypedGoRoute<DataAndStorageRoute>(path: 'dataAndStorage'),
        TypedGoRoute<ChatSettingsRoute>(
          path: 'chat',
          routes: [TypedGoRoute<EmotesRoute>(path: 'emotes')],
        ),
        TypedGoRoute<AddAccountRoute>(
          path: 'addaccount',
          routes: [
            TypedGoRoute<AddAccountLoginRoute>(path: 'login'),
            TypedGoRoute<AddAccountHomeserverPickerRoute>(
              path: 'homeserverpicker',
            ),
          ],
        ),
        TypedGoRoute<SecurityRoute>(
          path: 'security',
          routes: [
            TypedGoRoute<SecurityStoriesRoute>(path: 'stories'),
            TypedGoRoute<SecurityBlockedUsersRoute>(path: 'blockedUsers'),
            TypedGoRoute<Security3PidRoute>(path: '3pid'),
            TypedGoRoute<SecurityContactsVisibilityRoute>(
              path: 'contactsVisibility',
            ),
          ],
        ),
        TypedGoRoute<RoomRoute>(
          path: ':roomid',
          routes: [
            TypedGoRoute<EncryptionRoute>(path: 'encryption'),
            TypedGoRoute<InviteRoute>(path: 'invite'),
            TypedGoRoute<PinnedMessagesRoute>(path: 'pinnedmessages'),
          ],
        ),
      ],
    ),
  ],
)
class RoomsShellRoute extends ShellRouteData {
  const RoomsShellRoute();

  @override
  Page<void> pageBuilder(
    BuildContext context,
    GoRouterState state,
    Widget navigator,
  ) => _defaultPage(
    context,
    !_responsive.isMobile(context)
        ? AppAdaptiveScaffold(
            body: AppAdaptiveScaffoldBody(
              activeRoomId: state.pathParameters['roomid'],
              args: state.extra is AbsAppAdaptiveScaffoldBodyArgs
                  ? state.extra as AbsAppAdaptiveScaffoldBodyArgs
                  : null,
            ),
            secondaryBody: navigator,
          )
        : navigator,
  );
}

class RoomsRoute extends GoRouteData with $RoomsRoute {
  const RoomsRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(
        context,
        !_responsive.isMobile(context)
            ? const ChatBlank()
            : AppAdaptiveScaffoldBody(
                activeRoomId: state.pathParameters['roomid'],
                args: state.extra is AbsAppAdaptiveScaffoldBodyArgs
                    ? state.extra as AbsAppAdaptiveScaffoldBodyArgs
                    : null,
              ),
        name: '/rooms',
      );
}

// --- Stories ---

class StoriesCreateRoute extends GoRouteData with $StoriesCreateRoute {
  const StoriesCreateRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const AddStoryPage());
}

class StoryRoute extends GoRouteData with $StoryRoute {
  const StoryRoute({required this.roomid});
  final String roomid;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const StoryPage());
}

class StoryShareRoute extends GoRouteData with $StoryShareRoute {
  const StoryShareRoute({required this.roomid});
  final String roomid;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const AddStoryPage());
}

// --- Archive ---

class ArchiveRoute extends GoRouteData with $ArchiveRoute {
  const ArchiveRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const Archive());
}

class ArchiveRoomRoute extends GoRouteData with $ArchiveRoomRoute {
  const ArchiveRoomRoute({required this.roomid});
  final String roomid;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, ChatAdaptiveScaffold(roomId: roomid));
}

// --- New chat ---

class NewPrivateChatRoute extends GoRouteData with $NewPrivateChatRoute {
  const NewPrivateChatRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    if (!FirstColumnInnerRoutes.instance.goRouteAvailableInFirstColumn()) {
      return const RoomsRoute().location;
    }
    return _loggedOutRedirect(context, state);
  }

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const NewPrivateChat());
}

class NewPrivateChatNewGroupRoute extends GoRouteData
    with $NewPrivateChatNewGroupRoute {
  const NewPrivateChatNewGroupRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const NewGroup());
}

class NewPrivateChatNewGroupInfoRoute extends GoRouteData
    with $NewPrivateChatNewGroupInfoRoute {
  const NewPrivateChatNewGroupInfoRoute({this.$extra});
  final Set<PresentationContact>? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, NewGroupChatInfo(contactsList: $extra ?? {}));
}

class NewGroupRoute extends GoRouteData with $NewGroupRoute {
  const NewGroupRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const NewGroup());
}

// --- Draft chat ---

class DraftChatRoute extends GoRouteData with $DraftChatRoute {
  const DraftChatRoute({this.$extra});
  final Map<String, String>? $extra;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    if ($extra == null) {
      return const RoomsRoute().location;
    }
    return null;
  }

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      CupertinoPage(
        child: DraftChatAdaptiveScaffold(
          key: Key($extra?['receiverId'] ?? ''),
          state: state,
        ),
      );
}

// --- Forward ---

class ForwardRoute extends GoRouteData with $ForwardRoute {
  const ForwardRoute({this.$extra});
  final ForwardArgument? $extra;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    if ($extra == null) {
      return const RoomsRoute().location;
    }
    return null;
  }

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, Forward(sendFromRoomId: $extra?.fromRoomId));
}

// --- Share ---

class ShareRoute extends GoRouteData with $ShareRoute {
  const ShareRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const Share());
}

// --- Profile ---

class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const SettingsProfile());
}

class ProfileQrRoute extends GoRouteData with $ProfileQrRoute {
  const ProfileQrRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    if (!PlatformInfos.isMobile) {
      return const ProfileRoute().location;
    }
    return _loggedOutRedirect(context, state);
  }

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const PersonalQr());
}

// --- Settings ---

class NotificationsRoute extends GoRouteData with $NotificationsRoute {
  const NotificationsRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const SettingsNotifications());
}

class StyleRoute extends GoRouteData with $StyleRoute {
  const StyleRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const SettingsStyle());
}

class DevicesRoute extends GoRouteData with $DevicesRoute {
  const DevicesRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const DevicesSettings());
}

class AppLanguageRoute extends GoRouteData with $AppLanguageRoute {
  const AppLanguageRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const SettingsAppLanguage());
}

class DataAndStorageRoute extends GoRouteData with $DataAndStorageRoute {
  const DataAndStorageRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    if (!PlatformInfos.isMobile) {
      return const RoomsRoute().location;
    }
    return _loggedOutRedirect(context, state);
  }

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const SettingsDataAndStorage());
}

class ChatSettingsRoute extends GoRouteData with $ChatSettingsRoute {
  const ChatSettingsRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const SettingsChat());
}

class EmotesRoute extends GoRouteData with $EmotesRoute {
  const EmotesRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const EmotesSettings());
}

// --- Add account ---

class AddAccountRoute extends GoRouteData with $AddAccountRoute {
  const AddAccountRoute({this.$extra});
  final TwakeWelcomeArg? $extra;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, TwakeWelcome(arg: $extra));
}

class AddAccountLoginRoute extends GoRouteData with $AddAccountLoginRoute {
  const AddAccountLoginRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const Login());
}

class AddAccountHomeserverPickerRoute extends GoRouteData
    with $AddAccountHomeserverPickerRoute {
  const AddAccountHomeserverPickerRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(
        context,
        const HomeserverPicker(
          arg: HomeserverPickerArg(type: HomeserverPickerType.multiAccount),
        ),
      );
}

// --- Security ---

class SecurityRoute extends GoRouteData with $SecurityRoute {
  const SecurityRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const SettingsSecurity());
}

class SecurityStoriesRoute extends GoRouteData with $SecurityStoriesRoute {
  const SecurityStoriesRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const SettingsStories());
}

class SecurityBlockedUsersRoute extends GoRouteData
    with $SecurityBlockedUsersRoute {
  const SecurityBlockedUsersRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const BlockedUsers());
}

class Security3PidRoute extends GoRouteData with $Security3PidRoute {
  const Security3PidRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const Settings3Pid());
}

class SecurityContactsVisibilityRoute extends GoRouteData
    with $SecurityContactsVisibilityRoute {
  const SecurityContactsVisibilityRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const SettingsContactsVisibility());
}

// ===========================================================================
// Room route (the big one)
// ===========================================================================

class RoomRoute extends GoRouteData with $RoomRoute {
  const RoomRoute({required this.roomid, this.event, this.$extra});
  final String roomid;
  final String? event; // query param: ?event=xxx
  final Object? $extra;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final extra =
        $extra is ChatRouterInputArgument ? $extra as ChatRouterInputArgument : null;
    if (extra != null) {
      switch (extra.type) {
        case ChatRouterInputArgumentType.draft:
          return _buildRoomPage(
            context,
            state,
            prefix: 'Draft',
            roomName: extra.data is String ? extra.data as String? : null,
          );
        case ChatRouterInputArgumentType.share:
          return _buildRoomPage(
            context,
            state,
            prefix: 'Share',
            shareFiles: extra.data as List<MatrixFile?>?,
          );
      }
    }
    return _buildRoomPage(context, state, prefix: 'Default');
  }

  Page<void> _buildRoomPage(
    BuildContext context,
    GoRouterState state, {
    required String prefix,
    String? roomName,
    List<MatrixFile?>? shareFiles,
  }) {
    final name = '/rooms/room_$roomid';
    final key = prefix == 'Share'
        ? Key('${prefix}_${roomid}_${shareFiles.hashCode}')
        : Key('${prefix}_$roomid');
    final child = ChatAdaptiveScaffold(
      roomId: roomid,
      key: key,
      roomName: roomName,
      shareFiles: shareFiles,
    );

    if (_responsive.isMobile(context)) {
      return CupertinoPage(
        key: state.pageKey,
        name: name,
        restorationId: state.pageKey.value,
        child: child,
      );
    }

    return NoTransitionPage(
      key: state.pageKey,
      name: name,
      restorationId: state.pageKey.value,
      child: child,
    );
  }
}

// --- Room sub-routes ---

class EncryptionRoute extends GoRouteData with $EncryptionRoute {
  const EncryptionRoute({required this.roomid});
  final String roomid;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, const ChatEncryptionSettings());
}

class InviteRoute extends GoRouteData with $InviteRoute {
  const InviteRoute({required this.roomid});
  final String roomid;

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) =>
      _loggedOutRedirect(context, state);

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _defaultPage(context, InvitationSelection(roomId: roomid));
}

class PinnedMessagesRoute extends GoRouteData with $PinnedMessagesRoute {
  const PinnedMessagesRoute({required this.roomid, this.$extra});
  final String roomid;
  final PinnedEventsArgument? $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    if ($extra != null) {
      return MaterialPage(
        fullscreenDialog: true,
        child: PinnedMessages(
          pinnedEvents: $extra!.pinnedEvents,
          timeline: $extra!.timeline,
        ),
      );
    }
    return const CupertinoPage(child: PinnedMessages(pinnedEvents: []));
  }
}
