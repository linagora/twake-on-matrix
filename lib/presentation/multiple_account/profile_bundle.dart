import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

class ProfileBundlePresentation extends Equatable {
  final Profile profileBundle;
  final Client client;

  const ProfileBundlePresentation({
    required this.profileBundle,
    required this.client,
  });

  @override
  List<Object?> get props => [
        profileBundle,
        client,
      ];
}
