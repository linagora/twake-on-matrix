import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/message_link/policy/message_link_policy.dart';

part 'message_link_policy.provider.g.dart';

@riverpod
MessageLinkPolicy messageLinkPolicy(Ref ref) => const MessageLinkPolicy();
