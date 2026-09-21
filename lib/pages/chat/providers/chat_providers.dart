import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/services/room_send_queue_service.dart';
import 'package:twake_chat/domain/usecase/room/message_splitter.dart';
import 'package:twake_chat/domain/usecase/room/send_text_message_interactor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_providers.g.dart';

// Kept alive: it holds the pending sends of every room.
@Riverpod(keepAlive: true)
RoomSendQueueService roomSendQueueService(Ref ref) => RoomSendQueueService();

@riverpod
SendTextMessageInteractor sendTextMessageInteractor(Ref ref) =>
    SendTextMessageInteractor(
      splitter: const MessageSplitter(maxLength: AppConfig.maxMessageLength),
      sendQueue: ref.watch(roomSendQueueServiceProvider),
    );
