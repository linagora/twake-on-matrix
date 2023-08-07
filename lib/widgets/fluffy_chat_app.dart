import 'package:fluffychat/config/go_routes/go_router.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/network_connection_service.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/widgets/theme_builder.dart';
import '../config/app_config.dart';
import '../utils/custom_scroll_behaviour.dart';
import 'matrix.dart';

class FluffyChatApp extends StatefulWidget {
  final Widget? testWidget;
  final List<Client> clients;
  final Map<String, String>? queryParameters;
  static GlobalKey<NavigatorState> routerKey = GlobalKey<NavigatorState>();
  const FluffyChatApp({
    Key? key,
    this.testWidget,
    required this.clients,
    this.queryParameters,
  }) : super(key: key);

  /// getInitialLink may rereturn the value multiple times if this view is
  /// opened multiple times for example if the user logs out after they logged
  /// in with qr code or magic link.
  static bool gotInitialLink = false;

  @override
  FluffyChatAppState createState() => FluffyChatAppState();
}

class FluffyChatAppState extends State<FluffyChatApp> {
  final networkConnectionService = getIt.get<NetworkConnectionService>();
  final GoRouter router = TwakeRoutes().router;

  @override
  void initState() {
    super.initState();
    networkConnectionService.onInit();
  }

  @override
  void dispose() {
    super.dispose();
    networkConnectionService.onDispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeBuilder(
      builder: (context, themeMode, primaryColor) => MaterialApp.router(
        restorationScopeId: 'Twake',
        useInheritedMediaQuery: true,
        title: AppConfig.applicationName,
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: FluffyThemes.buildTheme(Brightness.light, primaryColor),
        darkTheme: FluffyThemes.buildTheme(Brightness.light, primaryColor),
        scrollBehavior: CustomScrollBehavior(),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        routeInformationProvider: router.routeInformationProvider,
        routeInformationParser: router.routeInformationParser,
        routerDelegate: router.routerDelegate,
        builder: (context, child) => Matrix(
          context: context,
          clients: widget.clients,
          globalRouteKey: router.routerDelegate.navigatorKey,
          child: child,
        ),
      ),
    );
  }
}
