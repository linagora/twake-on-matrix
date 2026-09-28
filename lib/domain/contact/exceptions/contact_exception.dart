/// Sealed hierarchy for contact-domain failures.
///
/// The domain throws these; the presentation maps them to user feedback.
/// No infrastructure type (Dio, Hive, Matrix SDK) must appear here.
sealed class ContactException implements Exception {
  const ContactException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No contact exists for the requested `matrixId`.
final class ContactNotFoundException extends ContactException {
  const ContactNotFoundException(this.matrixId)
    : super('No contact found for $matrixId');

  final String matrixId;
}

/// The contact payload is malformed / cannot be persisted.
final class InvalidContactException extends ContactException {
  const InvalidContactException(super.message, {this.cause});

  final Object? cause;
}

/// Local store (Hive) read/write failure.
final class ContactStorageException extends ContactException {
  const ContactStorageException(super.message, {this.cause});

  final Object? cause;
}

/// A remote source (TOM API, Matrix profile, identity lookup) failed.
final class ContactSyncException extends ContactException {
  const ContactSyncException(super.message, {this.cause});

  final Object? cause;
}
