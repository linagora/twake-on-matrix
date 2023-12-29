import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

class ClientProfilePresentation extends Equatable {
  final Profile profile;
  final Client client;

  const ClientProfilePresentation({
    required this.profile,
    required this.client,
  });

  @override
  List<Object?> get props => [
        profile,
        client,
      ];
}
