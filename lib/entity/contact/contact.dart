import 'package:equatable/equatable.dart';

class Contact extends Equatable {

  final Set<String> emails;

  final String displayName;

  final String? matrixUserId;

  const Contact({
    required this.emails,
    required this.displayName,
    this.matrixUserId
  });
  
  @override
  List<Object?> get props => [emails, displayName, matrixUserId];
}