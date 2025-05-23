import 'package:equatable/equatable.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/deep_link/deep_link_utils.dart';

class DeepLink with EquatableMixin {
  final String scheme;
  final String host;
  final Map<String, String>? queryParameters;

  DeepLink({required this.scheme, required this.host, this.queryParameters});

  @override
  List<Object?> get props => [scheme, host, queryParameters];
}

extension DeepLinkExtension on DeepLink {
  bool get isOpenAppAction =>
      scheme == AppConfig.appOpenUrlScheme && host == DeepLinkUtils.openAppHost;
}
