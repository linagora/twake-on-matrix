import 'package:equatable/equatable.dart';

import 'contact_status.dart';

class Contact extends Equatable {
  final Set<String>? emails;

  final String? displayName;

  final String? matrixId;

  final String? phoneNumber;

  final ContactStatus? status;

  const Contact({
    this.emails,
    this.displayName,
    this.matrixId,
    this.phoneNumber,
    this.status,
  });

  @override
  List<Object?> get props =>
      [emails, displayName, matrixId, phoneNumber, status];
}
