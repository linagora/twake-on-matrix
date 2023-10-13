import 'package:fluffychat/event/twake_event_types.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:fluffychat/config/app_config.dart';
import 'package:matrix/matrix.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uni_links/uni_links.dart';

mixin ReceiveSharingIntentMixin<T extends StatefulWidget> on State<T> {
  MatrixState get matrixState;

  StreamSubscription? intentDataStreamSubscription;

  StreamSubscription? intentFileStreamSubscription;

  StreamSubscription? intentUriStreamSubscription;

  void _processIncomingSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    final shareFile = files.first;
    final path = Uri.decodeFull(shareFile.path.replaceFirst('file://', ''));
    final file = File(path);
    matrixState.shareContent = {
      'msgtype': TwakeEventTypes.shareFileEventType,
      'file': MatrixFile(
        name: file.path,
        filePath: file.path,
      ).detectFileType,
    };
    TwakeApp.router.go('/share');
  }

  void _processIncomingSharedText(String? text) {
    if (text == null) return;
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
    TwakeApp.router.go('/share');
  }

  void _processIncomingUris(String? text) async {
    if (text == null) return;
    TwakeApp.router.go('/share');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UrlLauncher(context, text).openMatrixToUrl();
    });
  }

  void initReceiveSharingIntent() {
    if (!PlatformInfos.isMobile) return;

    // For sharing images coming from outside the app while the app is in the memory
    intentFileStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen(_processIncomingSharedFiles, onError: print);

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then(_processIncomingSharedFiles);

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    intentDataStreamSubscription = ReceiveSharingIntent.getTextStream()
        .listen(_processIncomingSharedText, onError: print);

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then(_processIncomingSharedText);

    // For receiving shared Uris
    intentUriStreamSubscription = linkStream.listen(_processIncomingUris);
    if (TwakeApp.gotInitialLink == false) {
      TwakeApp.gotInitialLink = true;
      getInitialLink().then(_processIncomingUris);
    }
  }
}
