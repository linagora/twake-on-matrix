import 'package:app_links/app_links.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/event/twake_event_types.dart';
import 'package:fluffychat/pages/share/share.dart';
import 'package:fluffychat/presentation/extensions/file_extension.dart';
import 'package:fluffychat/presentation/extensions/shared_media_file_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/layouts/agruments/receive_content_args.dart';
import 'package:fluffychat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

mixin ReceiveSharingIntentMixin<T extends StatefulWidget> on State<T> {
  MatrixState get matrixState;

  StreamSubscription? intentDataStreamSubscription;

  StreamSubscription? intentFileStreamSubscription;

  StreamSubscription? intentUriStreamSubscription;

  bool _intentOpenApp(String text) {
    return text.contains('twake.chat://openApp');
  }

  Future<void> _processIncomingSharedFiles(List<SharedMediaFile> files) async {
    Logs().d('ReceiveSharingIntentMixin::_processIncomingSharedFiles: $files');
    if (files.isEmpty) return;
    if (files.length == 1 && files.first.type == SharedMediaType.text) {
      Logs().d('Received text: ${files.first.path}');
      _processIncomingSharedText(files.first.path);
      return;
    }
    matrixState.shareContentList = await Future.wait(
      files.map(
        (sharedMediaFile) async {
          final file = sharedMediaFile.toFile();
          final matrixFile = await file.toMatrixFile();
          Logs().d(
            'ReceiveSharingIntentMixin::_processIncomingSharedFiles: Path ${matrixFile.filePath}',
          );
          Logs().d(
            'ReceiveSharingIntentMixin::_processIncomingSharedFiles: Size ${matrixFile.size}',
          );
          return {
            'msgtype': TwakeEventTypes.shareFileEventType,
            'file': matrixFile,
          };
        },
      ).toList(),
    );
    openSharePage();
  }

  void openSharePage() {
    if (TwakeApp.isCurrentPageIsNotRooms()) {
      return;
    }
    if (TwakeApp.isCurrentPageIsInRooms()) {
      TwakeApp.router.go(
        '/rooms',
        extra: ReceiveContentArgs(
          newActiveClient: matrixState.client,
          activeDestination: AdaptiveDestinationEnum.rooms,
        ),
      );
    }

    Navigator.of(TwakeApp.routerKey.currentContext!).push(
      MaterialPageRoute(
        builder: (context) => const Share(),
      ),
    );
  }

  void _processIncomingSharedText(String? text) {
    if (text == null) return;
    if (_intentOpenApp(text)) {
      return;
    }
    if (text.toLowerCase().startsWith(AppConfig.deepLinkPrefix) ||
        text.toLowerCase().startsWith(AppConfig.inviteLinkPrefix) ||
        (text.toLowerCase().startsWith(AppConfig.schemePrefix) &&
            !RegExp(r'\s').hasMatch(text))) {
      return _processIncomingUris(text);
    }
    matrixState.shareContent = {
      'msgtype': 'm.text',
      'body': text,
    };
    openSharePage();
  }

  void _processIncomingUris(String? text) async {
    Logs().d("ReceiveSharingIntentMixin: _processIncomingUris: $text");
    if (text == null) return;
    if (_intentOpenApp(text)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UrlLauncher(TwakeApp.routerKey.currentContext!, url: text)
          .openMatrixToUrl();
    });
  }

  void _clearPendingSharedFiles() {
    matrixState.shareContentList = null;
    matrixState.shareContent = null;
  }

  Future<void> initReceiveSharingIntent() async {
    if (!PlatformInfos.isMobile) return;

    // For sharing images coming from outside the app while the app is in the memory
    intentFileStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
      (shareMedia) async {
        await _processIncomingSharedFiles(shareMedia);
      },
      onError: print,
    );

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _clearPendingSharedFiles();
      _processIncomingSharedFiles(value);
      ReceiveSharingIntent.instance.reset();
    });

    // For receiving shared Uris
    final appLinks = AppLinks();
    intentUriStreamSubscription =
        appLinks.stringLinkStream.listen(_processIncomingUris);

    if (TwakeApp.gotInitialLink == false) {
      TwakeApp.gotInitialLink = true;
      appLinks.getInitialLinkString().then(_processIncomingUris);
    }
  }
}
