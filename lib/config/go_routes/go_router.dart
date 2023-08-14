import 'package:fluffychat/pages/add_story/add_story.dart';
import 'package:fluffychat/pages/archive/archive.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat_details/chat_details.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat.dart';
import 'package:fluffychat/pages/chat_encryption_settings/chat_encryption_settings.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/pages/story/story_page.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_route.dart';
import 'package:fluffychat/pages/chat_permissions_settings/chat_permissions_settings.dart';
import 'package:fluffychat/pages/connect/connect_page.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
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
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_shell.dart';
import 'package:fluffychat/widgets/layouts/empty_page.dart';
import 'package:fluffychat/widgets/log_view.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

class TwakeRoutes {
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  final _navRoomsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rooms');
  final _navContactsNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'Contacts');
  final _navStoriesNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'Stories');

  static const List<String> shellBranch = [
    '/rooms',
    '/contacts',
    '/stories',
  ];

  GoRouter get router => GoRouter(
        initialLocation: '/',
        navigatorKey: _rootNavigatorKey,
        debugLogDiagnostics: true,
        routes: [
          GoRoute(
            path: '/',
            redirect: (context, state) {
              final hasLogIn = Matrix.of(context).widget.clients.any(
                    (client) =>
                        client.onLoginStateChanged.value == LoginState.loggedIn,
                  );
              if (hasLogIn) {
                return '/rooms';
              } else {
                return '/home';
              }
            },
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const Login(),
          ),
          GoRoute(
            path: '/connect',
            builder: (context, state) => const ConnectPage(),
          ),
          GoRoute(
            path: '/signup',
            builder: (context, state) => const SignupPage(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeserverPicker(),
            routes: [
              GoRoute(
                path: 'login',
                builder: (context, state) => const Login(),
              ),
              GoRoute(
                path: 'logs',
                builder: (context, state) => const LogViewer(),
              ),
            ],
          ),
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return AdaptiveScaffoldShell(navigationShell: navigationShell);
            },
            branches: <StatefulShellBranch>[
              _contactsShellBranch,
              _roomsShellBranch,
              _storiesShellBranch,
            ],
          ),
          GoRoute(
            path: '/settings',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const Settings(),
            routes: _settingsRoutes,
          ),
          GoRoute(
            path: '/archive',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const Archive(),
            routes: [
              GoRoute(
                path: ':roomid',
                builder: (context, state) => const Chat(),
              ),
            ],
          ),
        ],
      );

  StatefulShellBranch get _roomsShellBranch => StatefulShellBranch(
        initialLocation: '/rooms',
        navigatorKey: _navRoomsNavigatorKey,
        routes: [
          GoRoute(
            path: '/rooms',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: AdaptiveScaffoldRoute(body: ChatList()),
              );
            },
            routes: [
              GoRoute(
                path: 'search',
                builder: (context, state) =>
                    const AdaptiveScaffoldRoute(body: Search()),
                routes: [
                  _draftChatRoute(body: const Search()),
                  _roomIdRoute(body: const Search()),
                ],
              ),
              GoRoute(
                path: 'newprivatechat',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AdaptiveScaffoldRoute(
                    body: ChatList(),
                    secondaryBody: NewPrivateChat(),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'newgroup',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: AdaptiveScaffoldRoute(
                        body: ChatList(),
                        secondaryBody: NewGroup(),
                      ),
                    ),
                  ),
                  _draftChatRoute(body: const ChatList()),
                ],
              ),
              _roomIdRoute(body: const ChatList()),
            ],
          ),
        ],
      );

  StatefulShellBranch get _contactsShellBranch => StatefulShellBranch(
        initialLocation: '/contacts',
        navigatorKey: _navContactsNavigatorKey,
        routes: [
          GoRoute(
            path: '/contacts',
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: AdaptiveScaffoldRoute(
                  body: ContactsTab(),
                ),
              );
            },
            routes: [
              _draftChatRoute(body: const ContactsTab()),
              _roomIdRoute(body: const ContactsTab()),
            ],
          ),
        ],
      );
  StatefulShellBranch get _storiesShellBranch => StatefulShellBranch(
        initialLocation: '/stories',
        navigatorKey: _navStoriesNavigatorKey,
        routes: [
          ShellRoute(
            pageBuilder: (context, state, widget) {
              return NoTransitionPage(
                child: AdaptiveScaffoldRoute(
                  body: Container(),
                  secondaryBody: widget,
                ),
              );
            },
            routes: [
              GoRoute(
                path: '/stories',
                builder: (context, state) {
                  return const EmptyPage();
                },
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const AddStoryPage(),
                  ),
                  GoRoute(
                    path: ':roomid',
                    builder: (context, state) => const StoryPage(),
                    routes: [
                      GoRoute(
                        path: 'share',
                        builder: (context, state) => const AddStoryPage(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

  GoRoute _draftChatRoute({
    String? path,
    required Widget body,
  }) =>
      GoRoute(
        path: path ?? 'draftChat',
        redirect: (context, state) {
          if (state.extra is! Map<String, String>) {
            return '${state.fullPath?.replaceAll('draftChat', '')}';
          } else {
            return path;
          }
        },
        pageBuilder: (context, state) {
          return CupertinoPage(
            child: AdaptiveScaffoldRoute(
              body: body,
              secondaryBody: DraftChat(
                key: state.pageKey,
                state: state,
              ),
            ),
          );
        },
      );

  GoRoute _roomIdRoute({required Widget body}) => GoRoute(
        path: ':roomid',
        pageBuilder: (context, state) => CupertinoPage(
          child: AdaptiveScaffoldRoute(
            body: body,
            secondaryBody: Chat(
              key: ValueKey(state.pathParameters['roomid'] ?? ""),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'encryption',
            builder: (context, state) => const ChatEncryptionSettings(),
          ),
          GoRoute(
            path: 'invite',
            builder: (context, state) => const InvitationSelection(),
          ),
          GoRoute(
            path: 'details',
            builder: (context, state) => const ChatDetails(),
            routes: _chatDetailsRoutes,
          ),
          GoRoute(
            path: 'forward',
            builder: (context, state) {
              return const Forward();
            },
          ),
        ],
      );

  List<RouteBase> get _chatDetailsRoutes => [
        GoRoute(
          path: 'permissions',
          builder: (context, state) => const ChatPermissionsSettings(),
        ),
        GoRoute(
          path: 'invite',
          builder: (context, state) => const InvitationSelection(),
        ),
        GoRoute(
          path: 'multiple_emotes',
          builder: (context, state) => const MultipleEmotesSettings(),
        ),
        GoRoute(
          path: 'emotes',
          builder: (context, state) => const EmotesSettings(),
        ),
        GoRoute(
          path: 'emotes/:state_key',
          builder: (context, state) => const EmotesSettings(),
        ),
        GoRoute(
          path: 'forward',
          builder: (context, state) {
            return const Forward();
          },
        )
      ];

  List<RouteBase> get _settingsRoutes => [
        GoRoute(
          path: 'notifications',
          builder: (context, state) => const SettingsNotifications(),
        ),
        GoRoute(
          path: 'style',
          builder: (context, state) => const SettingsStyle(),
        ),
        GoRoute(
          path: 'devices',
          builder: (context, state) => const DevicesSettings(),
        ),
        GoRoute(
          path: 'chat',
          builder: (context, state) => const SettingsChat(),
          routes: [
            GoRoute(
              path: 'emotes',
              builder: (context, state) => const EmotesSettings(),
            ),
          ],
        ),
        GoRoute(
          path: 'addaccount',
          builder: (context, state) => const HomeserverPicker(),
          routes: [
            GoRoute(
              path: 'login',
              builder: (context, state) => const Login(),
            ),
            GoRoute(
              path: 'connect',
              builder: (context, state) => const ConnectPage(),
              routes: [
                GoRoute(
                  path: 'login',
                  builder: (context, state) => const Login(),
                ),
                GoRoute(
                  path: 'signup',
                  builder: (context, state) => const SignupPage(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'security',
          builder: (context, state) => const SettingsSecurity(),
          routes: [
            GoRoute(
              path: 'stories',
              builder: (context, state) => const SettingsStories(),
            ),
            GoRoute(
              path: 'ignorelist',
              builder: (context, state) => const SettingsIgnoreList(),
            ),
            GoRoute(
              path: '3pid',
              builder: (context, state) => const Settings3Pid(),
            ),
          ],
        ),
        GoRoute(
          path: 'logs',
          builder: (context, state) => const LogViewer(),
        ),
      ];
}
