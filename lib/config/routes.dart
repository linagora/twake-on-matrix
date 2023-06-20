import 'package:fluffychat/di/contact/contact_di.dart';
import 'package:fluffychat/di/send_image/send_image_di.dart';
import 'package:fluffychat/pages/add_story/add_story.dart';
import 'package:fluffychat/pages/archive/archive.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat_details/chat_details.dart';
import 'package:fluffychat/pages/chat_encryption_settings/chat_encryption_settings.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/home_screen.dart';
import 'package:fluffychat/pages/chat_permissions_settings/chat_permissions_settings.dart';
import 'package:fluffychat/pages/connect/connect_page.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/device_settings/device_settings.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker.dart';
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
import 'package:fluffychat/pages/story/story_page.dart';
import 'package:fluffychat/widgets/layouts/empty_page.dart';
import 'package:fluffychat/widgets/layouts/loading_view.dart';
import 'package:fluffychat/widgets/layouts/side_view_layout.dart';
import 'package:fluffychat/widgets/layouts/two_column_layout.dart';
import 'package:fluffychat/widgets/log_view.dart';
import 'package:fluffychat/widgets/vwidget_with_dependency.dart';
import 'package:flutter/material.dart';
import 'package:vrouter/vrouter.dart';

class AppRoutes {
  final bool columnMode;

  AppRoutes(this.columnMode);

  List<VRouteElement> get routes => [
        ..._homeRoutes,
        if (columnMode) ..._tabletRoutes,
        if (!columnMode) ..._mobileRoutes,
      ];

  List<VRouteElement> get _mobileRoutes => [
        VRouter(routes: [
          VNester(
            key: const ValueKey("rooms"),
            path: '/rooms',
            widgetBuilder: (child) => HomeScreen(child: child,),
            buildTransition: _leftToRightTransition,
            nestedRoutes: [
              VWidget(
                path: null, 
                widget: const ChatList(),
                buildTransition: _bottomToTopTransition,
              ),
              VWidgetWithDependency(
                path: '/contactsTab', 
                widget: const ContactsTab(),
                di: ContactDI(),
                buildTransition: _bottomToTopTransition,
              ),
              VWidget(
                path: '/stories', 
                widget: const Scaffold(),
                buildTransition: _bottomToTopTransition,
              ),
            ],
          ),
          VPopHandler(
            onPop: (vRedirector) async {
              vRedirector.to('/rooms');
            },
            stackedRoutes: [
              VWidget(
                path: '/stories/create',
                widget: const AddStoryPage(),
                buildTransition: rightToLeftTransition,
              ),
              VWidget(
                path: '/stories/:roomid',
                widget: const StoryPage(),
                buildTransition: rightToLeftTransition,
                stackedRoutes: [
                  VWidget(
                    path: 'share',
                    widget: const AddStoryPage(),
                    buildTransition: rightToLeftTransition,
                  ),
                ],
              ),
              VWidget(
                path: '/spaces/:roomid',
                widget: const ChatDetails(),
                stackedRoutes: _chatDetailsRoutes,
                buildTransition: rightToLeftTransition,
              ),
              VWidgetWithDependency(
                path: '/rooms/:roomid',
                di: SendImageDi(),
                widget: const Chat(),
                buildTransition: rightToLeftTransition,
                stackedRoutes: [
                  VWidget(
                    path: 'encryption',
                    widget: const ChatEncryptionSettings(),
                    buildTransition: rightToLeftTransition,
                  ),
                  VWidget(
                    path: 'invite',
                    widget: const InvitationSelection(),
                    buildTransition: rightToLeftTransition,
                  ),
                  VWidget(
                    path: 'details',
                    widget: const ChatDetails(),
                    stackedRoutes: _chatDetailsRoutes,
                    buildTransition: rightToLeftTransition,
                  ),
                ],
              ),
              VWidget(
                path: '/settings',
                widget: const Settings(),
                stackedRoutes: _settingsRoutes,
                buildTransition: _bottomToTopTransition,
              ),
              VWidget(
                path: '/archive',
                widget: const Archive(),
                buildTransition: rightToLeftTransition,
                stackedRoutes: [
                  VWidget(
                    path: ':roomid',
                    widget: const Chat(),
                    buildTransition: rightToLeftTransition,
                  ),
                ],
              ),
              VWidgetWithDependency(
                di: ContactDI(),
                path: '/newprivatechat',
                widget: const NewPrivateChat(),
                buildTransition: rightToLeftTransition,
              ),
              VWidgetWithDependency(
                di: ContactDI(),
                path: '/newgroup',
                widget: const NewGroup(),
                buildTransition: rightToLeftTransition,
              ),
            ],
          )
        ],),
  ];
        
  List<VRouteElement> get _tabletRoutes => [
        VNester(
          path: '/rooms',
          widgetBuilder: (child) => TwoColumnLayout(
            mainView: const ChatList(),
            sideView: child,
          ),
          buildTransition: _fadeTransition,
          nestedRoutes: [
            VWidget(
              path: '',
              widget: const EmptyPage(),
              buildTransition: _fadeTransition,
              stackedRoutes: [
                VWidget(
                  path: '/stories/create',
                  buildTransition: _fadeTransition,
                  widget: const AddStoryPage(),
                ),
                VWidget(
                  path: '/stories/:roomid',
                  buildTransition: _fadeTransition,
                  widget: const StoryPage(),
                  stackedRoutes: [
                    VWidget(
                      path: 'share',
                      widget: const AddStoryPage(),
                    ),
                  ],
                ),
                VWidget(
                  path: '/spaces/:roomid',
                  widget: const ChatDetails(),
                  buildTransition: _fadeTransition,
                  stackedRoutes: _chatDetailsRoutes,
                ),
                VWidgetWithDependency(
                  di: ContactDI(),
                  path: '/newprivatechat',
                  widget: const NewPrivateChat(),
                  buildTransition: _fadeTransition,
                ),
                VWidgetWithDependency(
                  di: ContactDI(),
                  path: '/newgroup',
                  widget: const NewGroup(),
                  buildTransition: _fadeTransition,
                ),
                VNester(
                  path: ':roomid',
                  widgetBuilder: (child) => SideViewLayout(
                    mainView: const Chat(),
                    sideView: child,
                  ),
                  buildTransition: _fadeTransition,
                  nestedRoutes: [
                    VWidget(
                      path: '',
                      widget: const Chat(),
                      buildTransition: _fadeTransition,
                    ),
                    VWidget(
                      path: 'encryption',
                      widget: const ChatEncryptionSettings(),
                      buildTransition: _fadeTransition,
                    ),
                    VWidget(
                      path: 'details',
                      widget: const ChatDetails(),
                      buildTransition: _fadeTransition,
                      stackedRoutes: _chatDetailsRoutes,
                    ),
                    VWidget(
                      path: 'invite',
                      widget: const InvitationSelection(),
                      buildTransition: _fadeTransition,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        VWidget(
          path: '/rooms',
          widget: const TwoColumnLayout(
            mainView: ChatList(),
            sideView: EmptyPage(),
          ),
          buildTransition: _fadeTransition,
          stackedRoutes: [
            VNester(
              path: '/settings',
              widgetBuilder: (child) => TwoColumnLayout(
                mainView: const Settings(),
                sideView: child,
              ),
              buildTransition: _dynamicTransition,
              nestedRoutes: [
                VWidget(
                  path: '',
                  widget: const EmptyPage(),
                  buildTransition: _dynamicTransition,
                  stackedRoutes: _settingsRoutes,
                ),
              ],
            ),
            VNester(
              path: '/archive',
              widgetBuilder: (child) => TwoColumnLayout(
                mainView: const Archive(),
                sideView: child,
              ),
              buildTransition: _fadeTransition,
              nestedRoutes: [
                VWidget(
                  path: '',
                  widget: const EmptyPage(),
                  buildTransition: _dynamicTransition,
                ),
                VWidget(
                  path: ':roomid',
                  widget: const Chat(),
                  buildTransition: _dynamicTransition,
                ),
              ],
            ),
          ],
        ),
      ];

  List<VRouteElement> get _homeRoutes => [
        VWidget(path: '/', widget: const LoadingView()),
        VWidget(
          path: '/home',
          widget: const HomeserverPicker(),
          buildTransition: _fadeTransition,
          stackedRoutes: [
            VWidget(
              path: 'login',
              widget: const Login(),
              buildTransition: _fadeTransition,
            ),
            VWidget(
              path: 'connect',
              widget: const ConnectPage(),
              buildTransition: _fadeTransition,
              stackedRoutes: [
                VWidget(
                  path: 'login',
                  widget: const Login(),
                  buildTransition: _fadeTransition,
                ),
                VWidget(
                  path: 'signup',
                  widget: const SignupPage(),
                  buildTransition: _fadeTransition,
                ),
              ],
            ),
            VWidget(
              path: 'logs',
              widget: const LogViewer(),
              buildTransition: _dynamicTransition,
            ),
          ],
        ),
      ];

  List<VRouteElement> get _chatDetailsRoutes => [
        VWidget(
          path: 'permissions',
          widget: const ChatPermissionsSettings(),
          buildTransition: _dynamicTransition,
        ),
        VWidget(
          path: 'invite',
          widget: const InvitationSelection(),
          buildTransition: _dynamicTransition,
        ),
        VWidget(
          path: 'multiple_emotes',
          widget: const MultipleEmotesSettings(),
          buildTransition: _dynamicTransition,
        ),
        VWidget(
          path: 'emotes',
          widget: const EmotesSettings(),
          buildTransition: _dynamicTransition,
        ),
        VWidget(
          path: 'emotes/:state_key',
          widget: const EmotesSettings(),
          buildTransition: _dynamicTransition,
        ),
      ];

  List<VRouteElement> get _settingsRoutes => [
        VWidget(
          path: 'notifications',
          widget: const SettingsNotifications(),
          buildTransition: rightToLeftTransition,
        ),
        VWidget(
          path: 'style',
          widget: const SettingsStyle(),
          buildTransition: rightToLeftTransition,
        ),
        VWidget(
          path: 'devices',
          widget: const DevicesSettings(),
          buildTransition: rightToLeftTransition,
        ),
        VWidget(
          path: 'chat',
          widget: const SettingsChat(),
          buildTransition: rightToLeftTransition,
          stackedRoutes: [
            VWidget(
              path: 'emotes',
              widget: const EmotesSettings(),
              buildTransition: rightToLeftTransition,
            ),
          ],
        ),
        VWidget(
          path: 'addaccount',
          widget: const HomeserverPicker(),
          buildTransition: _fadeTransition,
          stackedRoutes: [
            VWidget(
              path: 'login',
              widget: const Login(),
              buildTransition: _fadeTransition,
            ),
            VWidget(
              path: 'connect',
              widget: const ConnectPage(),
              buildTransition: _fadeTransition,
              stackedRoutes: [
                VWidget(
                  path: 'login',
                  widget: const Login(),
                  buildTransition: _fadeTransition,
                ),
                VWidget(
                  path: 'signup',
                  widget: const SignupPage(),
                  buildTransition: _fadeTransition,
                ),
              ],
            ),
          ],
        ),
        VWidget(
          path: 'security',
          widget: const SettingsSecurity(),
          buildTransition: rightToLeftTransition,
          stackedRoutes: [
            VWidget(
              path: 'stories',
              widget: const SettingsStories(),
              buildTransition: rightToLeftTransition,
            ),
            VWidget(
              path: 'ignorelist',
              widget: const SettingsIgnoreList(),
              buildTransition: rightToLeftTransition,
            ),
            VWidget(
              path: '3pid',
              widget: const Settings3Pid(),
              buildTransition: rightToLeftTransition,
            ),
          ],
        ),
        VWidget(
          path: 'logs',
          widget: const LogViewer(),
          buildTransition: rightToLeftTransition,
        ),
      ];

  FadeTransition Function(dynamic, dynamic, dynamic)? get _dynamicTransition =>
      columnMode ? _fadeTransition : null;

  FadeTransition _fadeTransition(animation1, _, child) =>
      FadeTransition(opacity: animation1, child: child);
  
  SlideTransition _bottomToTopTransition(animation, secondaryAnimation, child) {
    return _buildSlideTransition(animation, secondaryAnimation, child, SlideTransitionType.bottomToTop);
  }

  SlideTransition _topToBottomTransition(animation, secondaryAnimation, child) {
    return _buildSlideTransition(animation, secondaryAnimation, child, SlideTransitionType.topToBottom);
  }

  SlideTransition _leftToRightTransition(animation, secondaryAnimation, child) {
    return _buildSlideTransition(animation, secondaryAnimation, child, SlideTransitionType.leftToRight);
  }

  static SlideTransition rightToLeftTransition(animation, secondaryAnimation, child) {
    return _buildSlideTransition(animation, secondaryAnimation, child, SlideTransitionType.rightToLeft);
  }

  static SlideTransition _buildSlideTransition(
    Animation animation, 
    Animation secondaryAnimation, 
    Widget child, 
    SlideTransitionType type,
  ) {
    final begin = type.begin;
    const end = Offset(0, 0);
    const curve = Curves.ease;
    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }
}

enum SlideTransitionType {
  bottomToTop(begin: Offset(0, 1)),
  topToBottom(begin: Offset(0, -1)),
  leftToRight(begin: Offset(-1, 0)),
  rightToLeft(begin: Offset(1, 0));

  final Offset begin;

  const SlideTransitionType({
    required this.begin,
  });
}