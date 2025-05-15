import 'dart:convert';

import 'package:fluffychat/presentation/model/deep_link/deep_link.dart';
import 'package:fluffychat/presentation/model/deep_link/open_app_deep_link.dart';
import 'package:matrix/matrix.dart';

class DeepLinkUtils {
  const DeepLinkUtils._();

  static const String openAppHost = 'openapp';

  static DeepLink? parseDeepLink(String url) {
    try {
      final decodedUrl = Uri.decodeFull(url);
      final uri = Uri.parse(decodedUrl);
      Logs().d('DeepLinkUtils::parseDeepLink: URI = $uri');
      final scheme = uri.scheme;
      final host = uri.host;
      final queryParameters = uri.queryParameters;

      return DeepLink(
        scheme: scheme,
        host: host,
        queryParameters: queryParameters,
      );
    } catch (e) {
      Logs().e('DeepLinkUtils::parseDeepLink: Exception = $e');
      return null;
    }
  }

  static OpenAppDeepLink? parseOpenAppDeepLink(
      Map<String, String>? queryParameters) {
    try {
      if (queryParameters == null || queryParameters.isEmpty) return null;

      final loginToken = queryParameters['loginToken'] ?? '';
      final data = queryParameters['data'] ?? '';

      if (data.isEmpty) return null;

      final Map<String, dynamic> dataJson = jsonDecode(data);
      final homeServer = dataJson['homeServer'] ?? '';
      final userId = dataJson['userId'] ?? '';

      return OpenAppDeepLink(
        loginToken: loginToken,
        homeServer: homeServer,
        userId: userId,
      );
    } catch (e) {
      Logs().e('DeepLinkUtils::parseOpenAppDeepLink: Exception = $e');
      return null;
    }
  }
}
