import 'package:equatable/equatable.dart';

class PresentationContact extends Equatable {

  final String email;

  final String displayName;

  const PresentationContact({
    required this.email,
    required this.displayName
  });
  
  @override
  List<Object?> get props => [email, displayName];
}