import 'package:collection/collection.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/usecase/send_file_interactor.dart';
import 'package:fluffychat/pages/share/share_view.dart';
import 'package:fluffychat/presentation/mixins/send_files_mixin.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class Share extends StatefulWidget {
  const Share({super.key});

  @override
  State<Share> createState() => ShareController();
}

class ShareController extends State<Share> with SendFilesMixin {
  final sendFileInteractor = getIt.get<SendFileInteractor>();

  final isShowRecentlyChatsNotifier = ValueNotifier(true);

  final AutoScrollController recentChatScrollController =
      AutoScrollController();

  final selectedRoomsNotifier = ValueNotifier(<String>[]);

  void onSelectChat(String id) {
    if (selectedRoomsNotifier.value.contains(id)) {
      selectedRoomsNotifier.value.remove(id);
    } else {
      selectedRoomsNotifier.value.add(id);
    }
    selectedRoomsNotifier.value = selectedRoomsNotifier.value.sorted(
      (current, next) => current.compareTo(next),
    );
  }

  void toggleRecentlyChats() {
    isShowRecentlyChatsNotifier.value = !isShowRecentlyChatsNotifier.value;
  }

  void shareTo(String roomId) async {
    final room = Room(
      id: selectedRoomsNotifier.value.first,
      client: Matrix.of(context).client,
    );
    final shareContent = Matrix.of(context).shareContent;
    if (shareContent != null) {
      final shareFile = shareContent.tryGet<MatrixFile>('file');
      if (shareContent.tryGet<String>('msgtype') == 'chat.fluffy.shared_file') {
        context.go('/rooms/${room.id}', extra: shareFile);
      } else {
        room.sendEvent(shareContent);
        context.go('/rooms/${room.id}');
      }
      Matrix.of(context).shareContent = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShareView(this);
  }
}
