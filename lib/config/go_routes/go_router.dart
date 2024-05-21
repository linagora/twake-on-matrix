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
import 'package:fluffychat/pages/error_page/error_page.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker.dart';
import 'package:fluffychat/pages/login/on_auth_redirect.dart';
import 'package:fluffychat/pages/new_group/new_group_chat_info.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_app_language/settings_app_language.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_profile/settings_profile.dart';
import 'package:fluffychat/pages/share/share.dart';
import 'package:fluffychat/pages/story/story_page.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome.dart';
import 'package:fluffychat/presentation/model/chat/chat_router_input_argument.dart';
import 'package:fluffychat/presentation/model/forward/forward_argument.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/app_adaptive_scaffold_body.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/app_adaptive_scaffold.dart';
import 'package:fluffychat/pages/connect/connect_page.dart';
import 'package:fluffychat/pages/device_settings/device_settings.dart';
import 'package:fluffychat/pages/forward/forward.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection.dart';
import 'package:fluffychat/pages/login/login.dart';
import 'package:fluffychat/pages/new_group/new_group.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_3pid/settings_3pid.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_chat/settings_chat.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_emotes/settings_emotes.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_ignore_list/settings_ignore_list.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_notifications/settings_notifications.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_security/settings_security.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_stories/settings_stories.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_style/settings_style.dart';
import 'package:fluffychat/pages/sign_up/signup.dart';
import 'package:fluffychat/widgets/layouts/agruments/app_adaptive_scaffold_body_args.dart';
import 'package:fluffychat/widgets/log_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

abstract class AppRoutes {
  static FutureOr<String?> loggedInRedirect(
    BuildContext context,
    GoRouterState state,
  ) =>
      Matrix.of(context).client.isLogged() ? '/rooms' : null;

  static FutureOr<String?> loggedOutRedirect(
    BuildContext context,
    GoRouterState state,
  ) =>
      Matrix.of(context).client.isLogged() ? null : '/home/twakeWelcome';

  AppRoutes();

  static final _responsive = getIt.get<ResponsiveUtils>();

  static final List<RouteBase> routes = [
    GoRoute(
      path: '/',
      redirect: (context, state) =>
          Matrix.of(context).client.isLogged() ? '/rooms' : '/home',
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => defaultPageBuilder(
        context,
        PlatformInfos.isMobile
            ? const TwakeWelcome()
            : AutoHomeserverPicker(
                loggedOut: state.extra is bool ? state.extra as bool? : null,
              ),
      ),
      redirect: loggedInRedirect,
      routes: [
        GoRoute(
          path: 'login',
          pageBuilder: (context, state) => defaultPageBuilder(
            context,
            const Login(),
          ),
          redirect: loggedInRedirect,
        ),
        GoRoute(
          path: 'twakeWelcome',
          pageBuilder: (context, state) => defaultPageBuilder(
            context,
            const TwakeWelcome(),
          ),
          redirect: loggedInRedirect,
        ),
        GoRoute(
          path: 'homeserverpicker',
          pageBuilder: (context, state) => defaultPageBuilder(
            context,
            const HomeserverPicker(),
          ),
          redirect: loggedInRedirect,
        ),
      ],
    ),
    GoRoute(
      path: '/onAuthRedirect',
      pageBuilder: (context, state) {
        return defaultPageBuilder(
          context,
          const OnAuthRedirect(),
        );
      },
    ),
    GoRoute(
      path: '/connect',
      pageBuilder: (context, state) => defaultPageBuilder(
        context,
        const ConnectPage(),
      ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => defaultPageBuilder(
        context,
        const SignupPage(),
      ),
    ),
    GoRoute(
      path: '/logs',
      pageBuilder: (context, state) => defaultPageBuilder(
        context,
        const LogViewer(),
      ),
    ),
    GoRoute(
      path: '/error',
      pageBuilder: (context, state) => defaultPageBuilder(
        context,
        const ErrorPage(),
      ),
    ),
    ShellRoute(
      pageBuilder: (context, state, child) => defaultPageBuilder(
        context,
        !_responsive.isMobile(context) &&
                state.fullPath?.startsWith('/rooms/settings') == false
            ? AppAdaptiveScaffold(
                body: AppAdaptiveScaffoldBody(
                  activeRoomId: state.pathParameters['roomid'],
                  args: state.extra is AbsAppAdaptiveScaffoldBodyArgs
                      ? state.extra as AbsAppAdaptiveScaffoldBodyArgs
                      : null,
                ),
                secondaryBody: child,
              )
            : child,
      ),
      routes: [
        GoRoute(
          path: '/rooms',
          redirect: loggedOutRedirect,
          pageBuilder: (context, state) => defaultPageBuilder(
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
          ),
          routes: [
            GoRoute(
              path: 'stories/create',
              pageBuilder: (context, state) => defaultPageBuilder(
                context,
                const AddStoryPage(),
              ),
              redirect: loggedOutRedirect,
            ),
            GoRoute(
              path: 'stories/:roomid',
              pageBuilder: (context, state) => defaultPageBuilder(
                context,
                const StoryPage(),
              ),
              redirect: loggedOutRedirect,
              routes: [
                GoRoute(
                  path: 'share',
                  pageBuilder: (context, state) => defaultPageBuilder(
                    context,
                    const AddStoryPage(),
                  ),
                  redirect: loggedOutRedirect,
                ),
              ],
            ),
            GoRoute(
              path: 'archive',
              pageBuilder: (context, state) => defaultPageBuilder(
                context,
                const Archive(),
              ),
              routes: [
                GoRoute(
                  path: ':roomid',
                  pageBuilder: (context, state) {
                    return defaultPageBuilder(
                      context,
                      ChatAdaptiveScaffold(
                        roomId: state.pathParameters['roomid']!,
                      ),
                    );
                  },
                  redirect: loggedOutRedirect,
                ),
              ],
              redirect: loggedOutRedirect,
            ),
            if (FirstColumnInnerRoutes.instance
                .goRouteAvailableInFirstColumn()) ...[
              GoRoute(
                path: 'newprivatechat',
                pageBuilder: (context, state) {
                  return defaultPageBuilder(
                    context,
                    const NewPrivateChat(),
                  );
                },
                redirect: loggedOutRedirect,
                routes: [
                  GoRoute(
                    path: 'newgroup',
                    pageBuilder: (context, state) => defaultPageBuilder(
                      context,
                      const NewGroup(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'newgroupinfo',
                        pageBuilder: (context, state) {
                          if (state.extra is Set<PresentationContact>) {
                            return defaultPageBuilder(
                              context,
                              NewGroupChatInfo(
                                contactsList:
                                    state.extra as Set<PresentationContact>,
                              ),
                            );
                          }
                          return defaultPageBuilder(
                            context,
                            const NewGroupChatInfo(contactsList: {}),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
            GoRoute(
              path: 'newgroup',
              pageBuilder: (context, state) => defaultPageBuilder(
                context,
                const NewGroup(),
              ),
              redirect: loggedOutRedirect,
            ),
            GoRoute(
              path: 'draftChat',
              redirect: (context, state) {
                if (state.extra is! Map<String, String>) {
                  return '${state.fullPath?.replaceAll('draftChat', '')}';
                } else {
                  return '/rooms/draftChat';
                }
              },
              pageBuilder: (context, state) {
                final extra = state.extra as Map<String, String>;
                return CupertinoPage(
                  child: DraftChatAdaptiveScaffold(
                    key: Key(extra['receiverId'] ?? ''),
                    state: state,
                  ),
                );
              },
            ),
            GoRoute(
              path: 'forward',
              redirect: (context, state) {
                if (state.extra is ForwardArgument) return '/rooms/forward';

                return '${state.fullPath?.replaceAll('forward', '')}';
              },
              pageBuilder: (context, state) {
                final extra = state.extra as ForwardArgument;
                return defaultPageBuilder(
                  context,
                  Forward(sendFromRoomId: extra.fromRoomId),
                );
              },
            ),
            GoRoute(
              path: 'profile',
              pageBuilder: (context, state) => defaultPageBuilder(
                context,
                const SettingsProfile(),
              ),
            ),
            GoRoute(
              path: 'notifications',
              pageBuilder: (context, state) => defaultPageBuilder(
                context,
                const SettingsNotifications(),
              ),
              redirect: loggedOutRedirect,
            ),
            GoRoute(
              path: 'style',
              pageBuilder: (context, state) => defaultPageBuilder(
                context,
                const SettingsStyle(),
              ),
              redirect: loggedOutRedirect,
            ),
            GoRoute(
              path: 'devices',
              pageBuilder: (context, state) => defaultPageBuilder(
                context,
                const DevicesSettings(),
              ),
              redirect: loggedOutRedirect,
            ),
            GoRoute(
              path: 'appLanguage',
              pageBuilder: (context, state) => defaultPageBuilder(
                context,
                const SettingsAppLanguage(),
              ),
              redirect: loggedOutRedirect,
            ),
            GoRoute(
              path: 'chat',
              pageBuilder: (context, state) => defaultPageBuilder(
                context,
                const SettingsChat(),
              ),
              routes: [
                GoRoute(
                  path: 'emotes',
                  pageBuilder: (context, state) => defaultPageBuilder(
                    context,
                    const EmotesSettings(),
                  ),
                ),
              ],
              redirect: loggedOutRedirect,
            ),
            GoRoute(
              path: 'addaccount',
              redirect: loggedOutRedirect,
              pageBuilder: (context, state) => defaultPageBuilder(
                context,
                TwakeWelcome(
                  arg: state.extra is TwakeWelcomeArg?
                      ? state.extra as TwakeWelcomeArg?
                      : null,
                ),
              ),
              routes: [
                GoRoute(
                  path: 'login',
                  pageBuilder: (context, state) => defaultPageBuilder(
                    context,
                    const Login(),
                  ),
                  redirect: loggedOutRedirect,
                ),
                GoRoute(
                  path: 'homeserverpicker',
                  pageBuilder: (context, state) => defaultPageBuilder(
                    context,
                    const HomeserverPicker(),
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'security',
              redirect: loggedOutRedirect,
              pageBuilder: (context, state) => defaultPageBuilder(
                context,
                const SettingsSecurity(),
              ),
              routes: [
                GoRoute(
                  path: 'stories',
                  pageBuilder: (context, state) => defaultPageBuilder(
                    context,
                    const SettingsStories(),
                  ),
                  redirect: loggedOutRedirect,
                ),
                GoRoute(
                  path: 'ignorelist',
                  pageBuilder: (context, state) => defaultPageBuilder(
                    context,
                    const SettingsIgnoreList(),
                  ),
                  redirect: loggedOutRedirect,
                ),
                GoRoute(
                  path: '3pid',
                  pageBuilder: (context, state) => defaultPageBuilder(
                    context,
                    const Settings3Pid(),
                  ),
                  redirect: loggedOutRedirect,
                ),
              ],
            ),
            GoRoute(
              path: ':roomid',
              pageBuilder: (context, state) {
                if (state.extra is ChatRouterInputArgument) {
                  final extra = state.extra as ChatRouterInputArgument;
                  switch (extra.type) {
                    case ChatRouterInputArgumentType.draft:
                      if (extra.data is String?) {
                        return CupertinoPage(
                          name: '/rooms/room',
                          child: ChatAdaptiveScaffold(
                            roomId: state.pathParameters['roomid']!,
                            key: Key(state.pathParameters['roomid']!),
                            roomName: extra.data as String?,
                          ),
                        );
                      }
                      return CupertinoPage(
                        name: '/rooms/room',
                        child: ChatAdaptiveScaffold(
                          roomId: state.pathParameters['roomid']!,
                          key: Key(state.pathParameters['roomid']!),
                        ),
                      );
                    case ChatRouterInputArgumentType.share:
                      return CupertinoPage(
                        name: '/rooms/room',
                        child: ChatAdaptiveScaffold(
                          roomId: state.pathParameters['roomid']!,
                          key: Key(state.pathParameters['roomid']!),
                          shareFiles: extra.data as List<MatrixFile?>?,
                        ),
                      );
                  }
                }
                return CupertinoPage(
                  name: '/rooms/room',
                  child: ChatAdaptiveScaffold(
                    roomId: state.pathParameters['roomid']!,
                    key: Key(state.pathParameters['roomid']!),
                  ),
                );
              },
              redirect: loggedOutRedirect,
              routes: [
                GoRoute(
                  path: 'encryption',
                  pageBuilder: (context, state) => defaultPageBuilder(
                    context,
                    const ChatEncryptionSettings(),
                  ),
                  redirect: loggedOutRedirect,
                ),
                GoRoute(
                  path: 'invite',
                  pageBuilder: (context, state) => defaultPageBuilder(
                    context,
                    InvitationSelection(
                      roomId: state.pathParameters['roomid']!,
                    ),
                  ),
                  redirect: loggedOutRedirect,
                ),
                GoRoute(
                  path: 'pinnedmessages',
                  pageBuilder: (context, state) {
                    if (state.extra is PinnedEventsArgument) {
                      final arg = state.extra as PinnedEventsArgument;
                      return MaterialPage(
                        fullscreenDialog: true,
                        child: PinnedMessages(
                          pinnedEvents: arg.pinnedEvents,
                          timeline: arg.timeline,
                        ),
                      );
                    }

                    return const CupertinoPage(
                      child: PinnedMessages(pinnedEvents: []),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/share',
          pageBuilder: (context, state) => defaultPageBuilder(
            context,
            const Share(),
          ),
          redirect: loggedOutRedirect,
        ),
      ],
    ),
  ];

  static Page defaultPageBuilder(
    BuildContext context,
    Widget child, {
    String? name,
  }) =>
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
}
