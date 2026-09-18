import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/usecase/room/message_splitter.dart';
import 'package:twake_chat/domain/usecase/room/send_text_message_interactor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_providers.g.dart';

@riverpod
SendTextMessageInteractor sendTextMessageInteractor(Ref ref) =>
    const SendTextMessageInteractor(
      splitter: MessageSplitter(maxLength: AppConfig.maxMessageLength),
    );
