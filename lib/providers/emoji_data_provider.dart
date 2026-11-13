import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'emoji_data_provider.g.dart';

/// The emojis the pickers offer. `MatrixState` waits for them at startup, so
/// a screen can read `requireValue`.
@Riverpod(keepAlive: true)
Future<EmojiData> emojiData(Ref ref) async {
  final all = await EmojiData.builtIn();
  return all.filterByVersion(13.5);
}
