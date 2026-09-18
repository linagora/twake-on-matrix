sealed class FeedException implements Exception {
  const FeedException(this.message, {this.cause});

  final String message;
  final Object? cause;
}

/// The homeserver does not know the feed preset, most likely because it has
/// not been patched yet.
class FeedNotSupportedByHomeserverException extends FeedException {
  const FeedNotSupportedByHomeserverException()
    : super('The homeserver does not support feeds');
}

class FeedCreationFailedException extends FeedException {
  const FeedCreationFailedException({required Object super.cause})
    : super('Failed to create the feed');
}
