import 'dart:io';

import 'package:dartz/dartz.dart' hide State, OpenFile;
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:fluffychat/utils/exception/downloading_exception.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/manager/download_manager/download_manager.dart';
import 'package:fluffychat/widgets/mixins/download_file_on_web_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'download_file_on_web_mixin_test.mocks.dart';

const fakeEventId = "fakeEventId";
const fakeFilename = "fakeFilename";

class MockRoom extends Mock implements Room {
  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    // ignore: unrelated_type_equality_checks
    return other is Room && other.id == id;
  }

  @override
  Map<String, MatrixFile> get sendingFilePlaceholders => super.noSuchMethod(
        Invocation.getter(#sendingFilePlaceholders),
        returnValue: <String, MatrixFile>{},
        returnValueForMissingStub: <String, MatrixFile>{},
      );
}

class MockEvent extends Mock implements Event {
  MockEvent(this.fakeRoom);
  final Room fakeRoom;
  @override
  String get eventId => fakeEventId;

  @override
  Room get room => fakeRoom;

  @override
  Map get infoMap => super.noSuchMethod(
        Invocation.getter(#infoMap),
        returnValue: {},
        returnValueForMissingStub: {},
      );
}

class DummyWidget extends StatefulWidget {
  const DummyWidget({required this.event, super.key});

  final Event event;

  @override
  // ignore: no_logic_in_create_state
  DummyWidgetState createState() => DummyWidgetState(event);
}

class DummyWidgetState extends State<DummyWidget> with DownloadFileOnWebMixin {
  DummyWidgetState(this.fakeEvent);

  final Event fakeEvent;

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  Event get event => fakeEvent;

  @override
  void handleDownloadMatrixFileSuccessDone({
    required DownloadMatrixFileSuccessState success,
  }) {}
}

@GenerateNiceMocks([
  MockSpec<File>(),
  MockSpec<DownloadManager>(),
])
void main() {
  group('DownloadFileOnWebMixin: setupDownloadingProcess', () {
    late DummyWidgetState dummyState;
    late Event fakeEvent;
    late Room fakeRoom;

    setUp(() {
      getIt.registerSingleton<DownloadManager>(MockDownloadManager());
      fakeRoom = MockRoom();
      fakeEvent = MockEvent(fakeRoom);
      dummyState = DummyWidgetState(fakeEvent);
    });

    tearDown(() {
      getIt.reset();
    });

    test('should handle failure', () {
      final failure = DownloadFileFailureState(exception: Exception());
      dummyState.setupDownloadingProcess(Left(failure));

      expect(
        dummyState.downloadFileStateNotifier.value,
        isInstanceOf<DownloadErrorPresentationState>(),
      );
    });

    test('should handle cancel', () {
      final failure = DownloadFileFailureState(
        exception: CancelDownloadingException(),
      );
      dummyState.setupDownloadingProcess(Left(failure));

      expect(
        dummyState.downloadFileStateNotifier.value,
        isInstanceOf<NotDownloadPresentationState>(),
      );
    });

    test('should handle success with DownloadingFileState', () {
      const success = DownloadingFileState(receive: 10, total: 100);
      dummyState.setupDownloadingProcess(const Right(success));

      expect(
        dummyState.downloadFileStateNotifier.value,
        isInstanceOf<DownloadingPresentationState>(),
      );
    });

    test('should handle success with DownloadMatrixFileSuccessState', () {
      TestWidgetsFlutterBinding.ensureInitialized();

      final success = DownloadMatrixFileSuccessState(
        matrixFile: MatrixFile(name: "name"),
      );
      dummyState.setupDownloadingProcess(Right(success));

      expect(
        dummyState.downloadFileStateNotifier.value,
        isInstanceOf<NotDownloadPresentationState>(),
      );
    });
  });
}
