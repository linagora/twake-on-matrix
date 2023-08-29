import 'dart:async';

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/add_story/add_story.dart';
import 'package:fluffychat/pages/archive/archive.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat_details/chat_details.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat.dart';
import 'package:fluffychat/pages/chat_encryption_settings/chat_encryption_settings.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker.dart';
import 'package:fluffychat/pages/share/share.dart';
import 'package:fluffychat/pages/story/story_page.dart';
import 'package:fluffychat/presentation/model/forward/forward_argument.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_route.dart';
import 'package:fluffychat/pages/chat_permissions_settings/chat_permissions_settings.dart';
import 'package:fluffychat/pages/connect/connect_page.dart';
import 'package:fluffychat/pages/device_settings/device_settings.dart';
import 'package:fluffychat/pages/forward/forward.dart';
import 'package:fluffychat/pages/invitation_selection/invitation_selection.dart';
import 'package:fluffychat/pages/login/login.dart';
import 'package:fluffychat/pages/new_group/new_group.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat.dart';
import 'package:fluffychat/pages/settings/settings.dart';
import 'package:fluffychat/pages/settings_3pid/settings_3pid.dart';
import 'package:fluffychat/pages/settings_chat/settings_chat.dart';
import 'package:fluffychat/pages/settings_emotes/settings_emotes.dart';
import 'package:fluffychat/pages/settings_ignore_list/settings_ignore_list.dart';
import 'package:fluffychat/pages/settings_multiple_emotes/settings_multiple_emotes.dart';
import 'package:fluffychat/pages/settings_notifications/settings_notifications.dart';
import 'package:fluffychat/pages/settings_security/settings_security.dart';
import 'package:fluffychat/pages/settings_stories/settings_stories.dart';
import 'package:fluffychat/pages/settings_style/settings_style.dart';
import 'package:fluffychat/pages/sign_up/signup.dart';
import 'package:fluffychat/widgets/layouts/empty_page.dart';
import 'package:fluffychat/widgets/log_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
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
      Matrix.of(context).client.isLogged() ? null : '/home';

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
        const HomeserverPicker(),
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
      ],
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
    ShellRoute(
      pageBuilder: (context, state, child) => defaultPageBuilder(
        context,
        !_responsive.isMobile(context) &&
                state.fullPath?.startsWith('/rooms/settings') == false
            ? AdaptiveScaffoldRoute(
                body: AdaptiveScaffoldApp(
                  activeRoomId: state.pathParameters['roomid'],
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
                ? const EmptyPage()
                : AdaptiveScaffoldApp(
                    activeRoomId: state.pathParameters['roomid'],
                  ),
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
                      Chat(
                        roomId: state.pathParameters['roomid']!,
                      ),
                    );
                  },
                  redirect: loggedOutRedirect,
                ),
              ],
              redirect: loggedOutRedirect,
            ),
            GoRoute(
              path: 'newprivatechat',
              pageBuilder: (context, state) => defaultPageBuilder(
                context,
                const NewPrivateChat(),
              ),
              redirect: loggedOutRedirect,
              routes: [
                GoRoute(
                  path: 'newgroup',
                  pageBuilder: (context, state) => defaultPageBuilder(
                    context,
                    const NewGroup(),
                  ),
                ),
              ],
            ),
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
                  child: DraftChat(
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
            ShellRoute(
              pageBuilder: (context, state, child) => defaultPageBuilder(
                context,
                !_responsive.isMobile(context)
                    ? AdaptiveScaffoldRoute(
                        displayAppBar: false,
                        body: const Settings(),
                        secondaryBody: child,
                      )
                    : child,
              ),
              routes: [
                GoRoute(
                  path: 'settings',
                  pageBuilder: (context, state) => defaultPageBuilder(
                    context,
                    !_responsive.isMobile(context)
                        ? const EmptyPage()
                        : const Settings(),
                  ),
                  routes: [
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
                        const HomeserverPicker(),
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
                  ],
                  redirect: loggedOutRedirect,
                ),
              ],
            ),
            GoRoute(
              path: ':roomid',
              pageBuilder: (context, state) {
                final shareFile = state.extra as MatrixFile?;
                return defaultPageBuilder(
                  context,
                  Chat(
                    roomId: state.pathParameters['roomid']!,
                    key: Key(state.pathParameters['roomid']!),
                    shareFile: shareFile,
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
                  path: 'details',
                  pageBuilder: (context, state) => defaultPageBuilder(
                    context,
                    ChatDetails(
                      roomId: state.pathParameters['roomid']!,
                    ),
                  ),
                  routes: [
                    GoRoute(
                      path: 'permissions',
                      pageBuilder: (context, state) => defaultPageBuilder(
                        context,
                        const ChatPermissionsSettings(),
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
                      path: 'multiple_emotes',
                      pageBuilder: (context, state) => defaultPageBuilder(
                        context,
                        const MultipleEmotesSettings(),
                      ),
                      redirect: loggedOutRedirect,
                    ),
                    GoRoute(
                      path: 'emotes',
                      pageBuilder: (context, state) => defaultPageBuilder(
                        context,
                        const EmotesSettings(),
                      ),
                      redirect: loggedOutRedirect,
                    ),
                    GoRoute(
                      path: 'emotes/:state_key',
                      pageBuilder: (context, state) => defaultPageBuilder(
                        context,
                        const EmotesSettings(),
                      ),
                      redirect: loggedOutRedirect,
                    ),
                  ],
                  redirect: loggedOutRedirect,
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

  static Page defaultPageBuilder(BuildContext context, Widget child) =>
      CustomTransitionPage(
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
