import 'package:matrix/matrix.dart';

class TwakeEventDispatcher {
  static final TwakeEventDispatcher _twakeEventDispatcher =
      TwakeEventDispatcher._instance();

  factory TwakeEventDispatcher() {
    return _twakeEventDispatcher;
  }

  TwakeEventDispatcher._instance();

  void sendAccountDataEvent({
    required Client client,
    required BasicEvent basicEvent,
  }) {
    client.onAccountData.add(basicEvent);
  }
}
