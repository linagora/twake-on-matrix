import 'package:equatable/equatable.dart';

class TwakeLookUpArgument with EquatableMixin {
  final String homeServerUrl;
  final String withAccessToken;

  TwakeLookUpArgument({
    required this.homeServerUrl,
    required this.withAccessToken,
  });

  @override
  List<Object?> get props => [homeServerUrl, withAccessToken];
}
