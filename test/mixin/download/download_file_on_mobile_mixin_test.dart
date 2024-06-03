import 'dart:io';

import 'package:dartz/dartz.dart' hide State, OpenFile, id;
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/exception/downloading_exception.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/manager/download_manager/download_manager.dart';
import 'package:fluffychat/widgets/mixins/download_file_on_mobile_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'download_file_on_mobile_mixin_test.mocks.dart';
import '../../utils/shared_mocks.dart';

class DummyWidget extends StatefulWidget {
  const DummyWidget({required this.event, super.key});

  final Event event;

  @override
  // ignore: no_logic_in_create_state
  DummyWidgetState createState() => DummyWidgetState(event);
}

class DummyWidgetState extends State<DummyWidget>
    with DownloadFileOnMobileMixin {
  DummyWidgetState(this.fakeEvent);

  final Event fakeEvent;

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  Event get event => fakeEvent;
}

@GenerateNiceMocks([
  MockSpec<File>(),
  MockSpec<DownloadManager>(),
])
void main() {
  group('DownloadFileOnMobileMixin: setupDownloadingProcess - ENV: WEB', () {
    late DummyWidgetState dummyState;
    late Event fakeEvent;
    late Room fakeRoom;

    setUpAll(() {
      getIt.registerSingleton<DownloadManager>(MockDownloadManager());
      fakeRoom = MockRoom();
      fakeEvent = MockEvent(fakeRoom);
      dummyState = DummyWidgetState(fakeEvent);
    });

    tearDownAll(() {
      getIt.reset();
    });

    test(
        'WHEN the download fails because of an Exception \n'
        'THEN downloadFileStateNotifier value should be DownloadErrorPresentationState \n',
        () {
      final failure = DownloadFileFailureState(exception: Exception());
      dummyState.setupDownloadingProcess(Left(failure));

      expect(
        dummyState.downloadFileStateNotifier.value,
        isInstanceOf<DownloadErrorPresentationState>(),
      );
    });

    test(
        'WHEN the user cancel the download \n'
        'THEN downloadFileStateNotifier value should be NotDownloadPresentationState \n',
        () {
      final failure =
          DownloadFileFailureState(exception: CancelDownloadingException());
      dummyState.setupDownloadingProcess(Left(failure));

      expect(
        dummyState.downloadFileStateNotifier.value,
        isInstanceOf<NotDownloadPresentationState>(),
      );
    });

    test(
        'WHEN download is in progress \n'
        'THEN downloadFileStateNotifier value should be DownloadingPresentationState \n',
        () {
      const success = DownloadingFileState(receive: 10, total: 100);
      dummyState.setupDownloadingProcess(const Right(success));

      expect(
        dummyState.downloadFileStateNotifier.value,
        isInstanceOf<DownloadingPresentationState>(),
      );
    });

    test(
        'WHEN download is successful \n'
        'THEN downloadFileStateNotifier value should be DownloadedPresentationState \n',
        () {
      const success = DownloadNativeFileSuccessState(filePath: 'path/to/file');
      dummyState.setupDownloadingProcess(const Right(success));

      expect(
        dummyState.downloadFileStateNotifier.value,
        isInstanceOf<DownloadedPresentationState>(),
      );
    });
  });

  group("DownloadFileOnMobileMixin: checkFileExistInMemory", () {
    setUpAll(() {
      getIt.registerSingleton<DownloadManager>(MockDownloadManager());
    });

    tearDownAll(() {
      getIt.reset();
    });

    test(
        'WHEN file already exists \n'
        'THEN downloadFileStateNotifier value should be DownloadedPresentationState \n',
        () {
      final fakeRoom = MockRoom();
      final fakeEvent = MockEvent(fakeRoom);
      final dummyState = DummyWidgetState(fakeEvent);

      when(fakeRoom.sendingFilePlaceholders).thenReturn(<String, MatrixFile>{
        MockEvent.fakeEventId: MatrixFile(
          name: fakeFilename,
          filePath: "path/to/file",
        ),
      });

      expect(dummyState.checkFileExistInMemory(), isTrue);
      expect(
        dummyState.downloadFileStateNotifier.value,
        isInstanceOf<DownloadedPresentationState>(),
      );
    });

    test(
        'WHEN file do not exists \n'
        'THEN downloadFileStateNotifier value should be NotDownloadPresentationState \n',
        () {
      final fakeRoom = MockRoom();
      final fakeEvent = MockEvent(fakeRoom);
      final dummyState = DummyWidgetState(fakeEvent);

      expect(dummyState.checkFileExistInMemory(), isFalse);
      expect(
        dummyState.downloadFileStateNotifier.value,
        isInstanceOf<NotDownloadPresentationState>(),
      );
    });
  });

  group("updateStateIfFileExists", () {
    setUpAll(() {
      getIt.registerSingleton<DownloadManager>(MockDownloadManager());
    });

    tearDownAll(() {
      getIt.reset();
    });

    test(
        'WHEN file already exists \n'
        'AND file size is the same as the event size \n'
        'THEN downloadFileStateNotifier value should be DownloadedPresentationState \n',
        () async {
      final fakeRoom = MockRoom();
      final fakeEvent = MockEvent(fakeRoom);
      final dummyState = DummyWidgetState(fakeEvent);

      final file = MockFile();
      when(file.exists()).thenAnswer((_) async => true);
      when(file.length()).thenAnswer((_) async => 123);
      when(fakeEvent.infoMap).thenReturn({'size': 123});
      when(file.path).thenReturn('path/to/file');

      await dummyState.updateStateIfFileExists(file);

      expect(
        dummyState.downloadFileStateNotifier.value,
        isInstanceOf<DownloadedPresentationState>(),
      );
    });

    test(
        'WHEN file does not exists \n'
        'THEN downloadFileStateNotifier value should be NotDownloadPresentationState \n',
        () async {
      final fakeRoom = MockRoom();
      final fakeEvent = MockEvent(fakeRoom);
      final dummyState = DummyWidgetState(fakeEvent);

      final file = MockFile();
      when(file.exists()).thenAnswer((_) async => false);
      when(file.length()).thenAnswer((_) async => 123);
      when(fakeEvent.infoMap).thenReturn({'size': 123});
      when(file.path).thenReturn('path/to/file');

      await dummyState.updateStateIfFileExists(file);

      expect(
        dummyState.downloadFileStateNotifier.value,
        isInstanceOf<NotDownloadPresentationState>(),
      );
    });

    test(
        'WHEN file already exists \n'
        'BUT file size is the not same as the event size \n'
        'THEN downloadFileStateNotifier value should be NotDownloadPresentationState \n',
        () async {
      final fakeRoom = MockRoom();
      final fakeEvent = MockEvent(fakeRoom);
      final dummyState = DummyWidgetState(fakeEvent);

      final file = MockFile();
      when(file.exists()).thenAnswer((_) async => true);
      when(file.length()).thenAnswer((_) async => 1234);
      when(fakeEvent.infoMap).thenReturn({'size': 123});
      when(file.path).thenReturn('path/to/file');

      await dummyState.updateStateIfFileExists(file);

      expect(
        dummyState.downloadFileStateNotifier.value,
        isInstanceOf<NotDownloadPresentationState>(),
      );
    });
  });
}
