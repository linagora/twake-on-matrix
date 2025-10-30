import 'package:equatable/equatable.dart';

class TwakeUserInfo with EquatableMixin {
  final String displayName;
  final Uri avatarUrl;
  final String matrixId;
  final String? email;
  final String? phoneNumber;

  TwakeUserInfo({
    required this.displayName,
    required this.avatarUrl,
    this.matrixId = '',
    this.email,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [
        displayName,
        avatarUrl,
        matrixId,
        email,
        phoneNumber,
      ];
}
