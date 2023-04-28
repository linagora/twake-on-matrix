import 'package:equatable/equatable.dart';

class Contact extends Equatable {

  final Set<String> emails;

  final String displayName;

  final String? matrixId;

  final String? phoneNumber;

  const Contact({
    required this.emails,
    required this.displayName,
    this.matrixId,
    this.phoneNumber,
  });
  
  @override
  List<Object?> get props => [emails, displayName, matrixId, phoneNumber];
}