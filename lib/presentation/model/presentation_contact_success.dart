import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/presentation/model/presentation_searchable_success.dart';

typedef PresentationContactsSuccess
    = PresentaionSearchableSuccess<PresentationContact>;

class PresentationExternalContactSuccess extends Success {
  final PresentationContact contact;

  const PresentationExternalContactSuccess({
    required this.contact,
  });

  @override
  List<Object?> get props => [contact];
}
