import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:twake_chat/pages/chat/events/download_video_widget.dart';
import 'package:twake_chat/pages/chat/events/event_video_player.dart';
import 'package:twake_chat/pages/chat/events/images_builder/message_content_image_builder.dart';
import 'package:twake_chat/pages/chat/events/message_download_content.dart';
import 'package:twake_chat/pages/chat/events/message_video_download_content.dart';
import 'package:twake_chat/pages/image_viewer/image_viewer.dart';
import 'package:twake_chat/utils/manager/storage_directory_manager.dart';
import 'package:twake_chat/widgets/file_widget/downloading_file_tile_widget.dart';
import 'package:twake_chat/widgets/file_widget/file_tile_widget.dart';
import 'package:twake_chat/widgets/matrix.dart' as twake;
import 'package:twake_chat/widgets/video_viewer_mobile_theme.dart';

import '../base/api_login_helper.dart';
import '../base/base_test_scenario.dart';
import '../base/media_fixture.dart';
import '../base/mobile_group_fixture.dart';
import '../base/core_robot.dart';

const _mediaRoomTitle = 'FTL Media Download Group';

/// The receiver gets media sent by another member through the API, then
/// opens or downloads it from the chat screen.
abstract class ChatMediaDownloadScenario extends BaseTestScenario {
  ChatMediaDownloadScenario(super.$, super.robots);

  String uniqueName(String prefix, String extension) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}.$extension';

  Future<MobileGroupFixture> prepareRoom() async {
    final fixture = await prepareMobileRoomFixture(this, _mediaRoomTitle);
    final context = $.tester.element(find.byType(Scaffold).first);
    final room = twake.Matrix.of(context).client.getRoomById(fixture.roomId);
    // The receiver sends unencrypted files and the download paths assume it.
    expect(
      room?.encrypted,
      isFalse,
      reason: '$_mediaRoomTitle must be unencrypted (server default changed?)',
    );
    return fixture;
  }

  Future<void> openRoom(MobileGroupFixture fixture) async {
    await robots.chatListRobot().openSearchScreen();
    final opened = await robots.searchViewRobot().searchAndOpenRoom(
      fixture.title,
    );
    if (!opened) {
      throw Exception('Test failed: Room "${fixture.title}" was not found.');
    }
  }

  Finder fileMessage(String name) => find.byWidgetPredicate(
    (widget) => widget is MessageDownloadContent && widget.event.body == name,
  );

  Future<String> downloadedPath(String eventId, String name) =>
      StorageDirectoryManager.instance.getFilePathInAppDownloads(
        eventId: eventId,
        fileName: name,
      );

  Future<void> expectDownloaded({
    required String eventId,
    required ReceiverMediaFile file,
  }) async {
    await $(
      fileMessage(file.name),
    ).$(FileTileWidget).waitUntilVisible(timeout: const Duration(seconds: 60));
    final downloaded = File(await downloadedPath(eventId, file.name));
    expect(
      await downloaded.exists(),
      isTrue,
      reason: '${file.name} should be saved in the app downloads',
    );
    expect(
      await downloaded.length(),
      file.bytes.length,
      reason: '${file.name} should be downloaded in full',
    );
  }
}

class ReceiverOpensImageScenario extends ChatMediaDownloadScenario {
  ReceiverOpensImageScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final fixture = await prepareRoom();
    final name = uniqueName('e2e-image', 'png');
    await sendMediaAsReceiver(
      roomId: fixture.roomId,
      msgtype: MessageTypes.Image,
      file: imageFixture(name),
    );
    await openRoom(fixture);

    final bubble = $(
      find.byWidgetPredicate(
        (widget) => widget is MessageImageBuilder && widget.event.body == name,
      ),
    );
    await bubble.waitUntilVisible(timeout: const Duration(seconds: 30));
    await bubble.tap();

    await $(
      find.byWidgetPredicate(
        (widget) => widget is ImageViewer && widget.event?.body == name,
      ),
    ).waitUntilVisible(timeout: const Duration(seconds: 30));
  }
}

class ReceiverDownloadsAndPlaysVideoScenario extends ChatMediaDownloadScenario {
  ReceiverDownloadsAndPlaysVideoScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final fixture = await prepareRoom();
    final name = uniqueName('e2e-video', 'mp4');
    await sendMediaAsReceiver(
      roomId: fixture.roomId,
      msgtype: MessageTypes.Video,
      file: videoFixture(name),
    );
    await openRoom(fixture);

    final bubble = $(
      find.byWidgetPredicate(
        (widget) =>
            widget is MessageVideoDownloadContent && widget.event.body == name,
      ),
    );
    await bubble.waitUntilVisible(timeout: const Duration(seconds: 30));
    final downloadButton = bubble.$(
      find.widgetWithIcon(CenterVideoButton, Icons.arrow_downward),
    );
    await downloadButton.waitUntilVisible();
    await downloadButton.tap();

    final viewer = $(
      find.byWidgetPredicate(
        (widget) => widget is DownloadVideoWidget && widget.event.body == name,
      ),
    );
    await viewer.waitUntilVisible(timeout: const Duration(seconds: 30));
    await CoreRobot($).waitUntilAbsent(
      $,
      viewer.$(CircularProgressIndicator),
      timeout: const Duration(seconds: 60),
    );
    await viewer.$(find.byIcon(Icons.play_arrow)).tap();

    await $(
      VideoViewerMobileTheme,
    ).waitUntilVisible(timeout: const Duration(seconds: 30));
    await _expectVideoPlays();
  }

  static const _durationTolerance = Duration(milliseconds: 200);

  // On the Android emulator the position never leaves zero, so the check
  // stops at the player having parsed the downloaded file and started.
  Future<void> _expectVideoPlays() async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      final videos = $(Video).evaluate();
      if (videos.isNotEmpty) {
        final state = (videos.first.widget as Video).controller.player.state;
        final durationGap = (state.duration - videoFixtureDuration).abs();
        if (state.playing && durationGap <= _durationTolerance) return;
      }
      await $.pump(const Duration(milliseconds: 500));
    }
    fail('The player never started the downloaded video');
  }
}

class ReceiverDownloadsAndOpensPdfScenario extends ChatMediaDownloadScenario {
  ReceiverDownloadsAndOpensPdfScenario(super.$, super.robots);

  static const _openFileChannel = MethodChannel('open_file');

  @override
  Future<void> runTestLogic() async {
    final fixture = await prepareRoom();
    final file = pdfFixture(uniqueName('e2e-file', 'pdf'));
    final eventId = await sendMediaAsReceiver(
      roomId: fixture.roomId,
      msgtype: MessageTypes.File,
      file: file,
    );
    await openRoom(fixture);

    final message = $(fileMessage(file.name));
    await message
        .$(DownloadingFileTileWidget)
        .waitUntilVisible(timeout: const Duration(seconds: 30));
    await message.$(DownloadingFileTileWidget).tap();
    await expectDownloaded(eventId: eventId, file: file);

    // The PDF viewer belongs to the OS: record the hand-off instead.
    final openCalls = <MethodCall>[];
    final messenger = $.tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_openFileChannel, (call) async {
      openCalls.add(call);
      return jsonEncode({'type': 0, 'message': 'done'});
    });
    try {
      await message.$(FileTileWidget).tap();
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (openCalls.isEmpty && DateTime.now().isBefore(deadline)) {
        await $.pump(const Duration(milliseconds: 200));
      }
    } finally {
      messenger.setMockMethodCallHandler(_openFileChannel, null);
    }

    expect(openCalls, hasLength(1), reason: 'Tapping the PDF should open it');
    final arguments = openCalls.single.arguments as Map;
    expect(arguments['file_path'], await downloadedPath(eventId, file.name));
    expect(arguments['type'], 'application/pdf');
  }
}

class ReceiverDownloadsSeveralPdfsScenario extends ChatMediaDownloadScenario {
  ReceiverDownloadsSeveralPdfsScenario(super.$, super.robots);

  static const _fileCount = 3;

  @override
  Future<void> runTestLogic() async {
    final fixture = await prepareRoom();
    final files = [
      for (var i = 0; i < _fileCount; i++)
        pdfFixture(uniqueName('e2e-multi-$i', 'pdf'), paddedTo: 2 << 20),
    ];
    final eventIds = [
      for (final file in files)
        await sendMediaAsReceiver(
          roomId: fixture.roomId,
          msgtype: MessageTypes.File,
          file: file,
        ),
    ];
    await openRoom(fixture);

    for (final file in files) {
      await $(fileMessage(file.name))
          .$(DownloadingFileTileWidget)
          .waitUntilVisible(timeout: const Duration(seconds: 30));
    }

    // Start every download before any of them can finish.
    for (final file in files) {
      await $.tester.tap(
        find.descendant(
          of: fileMessage(file.name),
          matching: find.byType(DownloadingFileTileWidget),
        ),
      );
      await $.pump();
    }
    for (final file in files) {
      await CoreRobot($).waitUntilAbsent(
        $,
        $(fileMessage(file.name)).$(DownloadingFileTileWidget),
        timeout: const Duration(seconds: 10),
      );
    }

    for (var i = 0; i < _fileCount; i++) {
      await expectDownloaded(eventId: eventIds[i], file: files[i]);
    }
  }
}
