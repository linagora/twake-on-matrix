import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';

/// A [ContactSourceValue] already resolved to a Matrix ID.
///
/// Contacts that cannot be keyed by a `matrixId` are not part of the unified
/// read model (it is keyed by `matrixId`); they stay in the legacy flows until
/// the identity lookup resolves them.
class SourcedContact {
  const SourcedContact({required this.matrixId, required this.value});

  final String matrixId;
  final ContactSourceValue value;
}

/// A read-only provider of contact values for one source.
///
/// Implementations live in `data/` and are the only place that talks to an
/// external system (TOM API, device phonebook, Matrix SDK).
abstract class ContactSource {
  ContactSourceKind get kind;

  Future<List<SourcedContact>> fetch();
}
