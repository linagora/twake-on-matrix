import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/model/contact/contact_type.dart';

class PresentationContact extends Equatable {
  final String? email;

  final String? phoneNumber;

  final String? displayName;

  final String? matrixId;

  final ContactStatus? status;

  final ContactType? type;

  const PresentationContact({
    this.email,
    this.phoneNumber,
    this.displayName,
    this.matrixId,
    this.status,
    this.type,
  });

  PresentationContact get presentationContactEmpty => const PresentationContact(
        email: '',
        displayName: '',
        matrixId: '',
        status: ContactStatus.inactive,
      );

  @override
  List<Object?> get props =>
      [email, phoneNumber, displayName, matrixId, status, type];
}
