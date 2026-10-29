/// Which screen discards the pending login client when the user leaves the
/// flow without logging in.
enum LoginClientOwner {
  /// The screen was reached on its own (deep link, web refresh), so it made
  /// the client and drops it on exit.
  thisPage,

  /// The screen that pushed this one made the client and drops it on exit.
  caller,
}
