import 'package:equatable/equatable.dart';

import 'contact_status.dart';

class Contact extends Equatable {
  final String? email;

  final String? displayName;

  final String? matrixId;

  final String? phoneNumber;

  final ContactStatus? status;

  const Contact({
    this.email,
    this.displayName,
    this.matrixId,
    this.phoneNumber,
    this.status,
  });

  @override
  List<Object?> get props =>
      [email, displayName, matrixId, phoneNumber, status];
}
