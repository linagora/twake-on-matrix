import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/presentation/model/deep_link/deep_link.dart';
import 'package:fluffychat/utils/deep_link/deep_link_utils.dart';

class OpenAppDeepLink extends DeepLink {
  final String loginToken;
  final String homeServer;
  final String userId;

  OpenAppDeepLink({
    required this.loginToken,
    required this.homeServer,
    required this.userId,
  }) : super(
          scheme: AppConfig.appOpenUrlScheme,
          host: DeepLinkUtils.openAppHost,
        );

  String get homeServerUrl =>
      homeServer.startsWith('https://') ? homeServer : 'https://$homeServer';

  String get qualifiedUserId =>
      userId.startsWith('@') && userId.endsWith(':$homeServer')
          ? userId
          : '@$userId:$homeServer';

  @override
  List<Object?> get props => [
        scheme,
        host,
        loginToken,
        homeServer,
        userId,
      ];
}
