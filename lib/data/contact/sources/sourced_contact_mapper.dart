import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/model/contact/contact.dart';

/// Maps a legacy domain [Contact] to a [SourcedContact].
///
/// Returns `null` when the contact has no Matrix ID: unresolved contacts are
/// not part of the `matrixId`-keyed read model.
SourcedContact? contactToSourcedContact({
  required Contact contact,
  required ContactSourceKind kind,
  DateTime? updatedAt,
}) {
  final matrixId = _resolveMatrixId(contact);
  if (matrixId == null) return null;

  return SourcedContact(
    matrixId: matrixId,
    value: ContactSourceValue(
      kind: kind,
      displayName: contact.displayName,
      emails: _nonEmpty(contact.emails?.map((email) => email.address)),
      phones: _nonEmpty(contact.phoneNumbers?.map((phone) => phone.number)),
      updatedAt: updatedAt,
    ),
  );
}

String? _resolveMatrixId(Contact contact) {
  for (final email in contact.emails ?? const <Email>{}) {
    final matrixId = email.matrixId;
    if (matrixId != null && matrixId.trim().isNotEmpty) return matrixId;
  }
  for (final phone in contact.phoneNumbers ?? const <PhoneNumber>{}) {
    final matrixId = phone.matrixId;
    if (matrixId != null && matrixId.trim().isNotEmpty) return matrixId;
  }
  return null;
}

List<String> _nonEmpty(Iterable<String>? values) {
  if (values == null) return const <String>[];
  return values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}
