import 'package:matrix/matrix.dart';

extension VoiceMessageExtension on Event {
  bool get isVoiceMessage =>
      !redacted &&
      messageType == MessageTypes.Audio &&
      content.containsKey('org.matrix.msc3245.voice');
}
