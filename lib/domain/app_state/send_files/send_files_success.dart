import 'package:twake_chat/app_state/success.dart';

class SendFilesSuccess extends Success {
  final List<String>? eventIds;

  const SendFilesSuccess({this.eventIds});

  @override
  List<Object?> get props => [eventIds];
}
