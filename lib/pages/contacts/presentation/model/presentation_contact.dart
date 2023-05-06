import 'package:equatable/equatable.dart';

class PresentationContact extends Equatable {

  final String email;

  final String displayName;

  final String? matrixUserId;

  const PresentationContact({
    required this.email,
    required this.displayName,
    this.matrixUserId
  });
  
  @override
  List<Object?> get props => [email, displayName, matrixUserId];
}