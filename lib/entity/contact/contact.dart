import 'package:equatable/equatable.dart';

class Contact extends Equatable {

  final Set<String> emails;

  final String displayName;

  const Contact({
    required this.emails,
    required this.displayName
  });
  
  @override
  List<Object?> get props => [emails, displayName];
}