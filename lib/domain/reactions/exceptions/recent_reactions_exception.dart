sealed class RecentReactionsException implements Exception {
  const RecentReactionsException(this.cause);

  final Object cause;

  @override
  String toString() => '$runtimeType: $cause';
}

class GetRecentReactionsException extends RecentReactionsException {
  const GetRecentReactionsException(super.cause);
}

class StoreRecentReactionsException extends RecentReactionsException {
  const StoreRecentReactionsException(super.cause);
}
