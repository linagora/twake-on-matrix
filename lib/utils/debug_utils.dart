class DebugUtils {
  static final DebugUtils _instance = DebugUtils._internal();

  static bool enableLogs = false;

  DebugUtils._internal();

  factory DebugUtils() {
    return _instance;
  }

  bool get isDebugMode {
    if (enableLogs) {
      return enableLogs;
    }
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
}
