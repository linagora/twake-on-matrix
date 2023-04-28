import 'package:equatable/equatable.dart';

class PresentationContact extends Equatable {

  final String email;

  final String displayName;

  final String? matrixId;

  const PresentationContact({
    required this.email,
    required this.displayName,
    this.matrixId
  });
  
  @override
  List<Object?> get props => [email, displayName, matrixId];
}