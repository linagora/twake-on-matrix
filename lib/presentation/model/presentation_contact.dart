import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';

class PresentationContact extends Equatable {

  final String? email;

  final String? displayName;

  final String? matrixId;

  final ContactStatus? status;

  const PresentationContact({
    this.email,
    this.displayName,
    this.matrixId,
    this.status,
  });

  PresentationContact get presentationContactEmpty => const PresentationContact(
    email: '',
    displayName: '',
    matrixId: '',
    status: ContactStatus.inactive,
  );
  
  @override
  List<Object?> get props => [email, displayName, matrixId, status];
}