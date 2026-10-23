enum CozyBridgeMethod {
  get,
  post,
  put,
  patch,
  delete;

  String get wireName => name.toUpperCase();
}

abstract interface class CozyBridge {
  bool get isAvailable;

  Future<Object?> fetchJson({
    required CozyBridgeMethod method,
    required String path,
    required Map<String, dynamic> body,
  });
}
