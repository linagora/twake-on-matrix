/// A message as a chat screen shows it.
class ShownMessage {
  const ShownMessage({required this.eventId, required this.isVoiceMessage});

  final String eventId;
  final bool isVoiceMessage;
}
