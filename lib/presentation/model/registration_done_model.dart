import 'package:equatable/equatable.dart';
import 'package:fluffychat/utils/string_extension.dart';

class RegistrationDoneModel with EquatableMixin {
  final String? openApp;

  final String? playStoreUrl;

  final String? appStoreUrl;

  RegistrationDoneModel({this.openApp, this.playStoreUrl, this.appStoreUrl});

  factory RegistrationDoneModel.fromUrl(String url) {
    final uri = Uri.parse(url);
    final queryParameters = uri.queryParameters;
    return RegistrationDoneModel(
      openApp: queryParameters['open_app']?.base64DecodedString(),
      playStoreUrl: queryParameters['play_store_url']?.base64DecodedString(),
      appStoreUrl: queryParameters['app_store_url']?.base64DecodedString(),
    );
  }

  @override
  List<Object?> get props => [openApp, playStoreUrl];
}
