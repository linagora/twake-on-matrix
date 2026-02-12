import 'package:dartz/dartz.dart';
import 'package:fluffychat/utils/exception/upload_exception.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_manager.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'upload_manager_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<MatrixFile>(),
  MockSpec<UploadManager>(),
])
void main() {
  late MockUploadManager uploadManager;
  late MockClient client;
  late Room room;

  Map<String, dynamic> creatEvent(String eventId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    const senderID = '@alice:server.abc';
    const type = 'm.room.message';
    const msgtype = 'm.text';
    const body = 'Hello World';
    const formattedBody = '<b>Hello</b> World';

    const contentJson =
        '{"msgtype":"$msgtype","body":"$body","formatted_body":"$formattedBody","m.relates_to":{"m.in_reply_to":{"event_id":"\$1234:example.com"}}}';

    return <String, dynamic>{
      'event_id': eventId,
      'sender': senderID,
      'origin_server_ts': timestamp,
      'type': type,
      'room_id': '!testroom:example.abc',
      'status': EventStatus.synced.intValue,
      'content': contentJson,
    };
  }

  const id = '!localpart:server.abc';
  const membership = Membership.join;
  const notificationCount = 2;
  const highlightCount = 1;
  final heroes = [
    '@alice:matrix.org',
    '@bob:example.com',
    '@charley:example.org',
  ];

  setUp(() {
    client = MockClient();
    uploadManager = MockUploadManager();
    room = Room(
      client: client,
      id: id,
      membership: membership,
      highlightCount: highlightCount,
      notificationCount: notificationCount,
      prev_batch: '',
      summary: RoomSummary.fromJson({
        'm.joined_member_count': 2,
        'm.invited_member_count': 2,
        'm.heroes': heroes,
      }),
      roomAccountData: {
        'com.test.foo': BasicEvent(
          type: 'com.test.foo',
          content: {'foo': 'bar'},
        ),
        'm.fully_read': BasicEvent(
          type: 'm.fully_read',
          content: {'event_id': '\$event_id:example.com'},
        ),
      },
    );
  });
  group('UploadManager test on WEB', () {
    test('\nWHEN pick file successfully and upload a file.\n'
        'THEN upload file successfully.\n', () async {
      const txidA = 'txidA';

      final mockMatrixFile = List.generate(1, (_) => MockMatrixFile());

      when(room.client.generateUniqueTransactionId()).thenReturn(txidA);

      when(uploadManager.getUploadStateStream(txidA)).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          const Right(UploadFileSuccessState(eventId: txidA)),
        ]),
      );

      await uploadManager.uploadFilesWeb(room: room, files: mockMatrixFile);

      expect(room.client.generateUniqueTransactionId(), equals(txidA));

      expect(
        uploadManager.getUploadStateStream(txidA),
        emitsInOrder([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          const Right(UploadFileSuccessState(eventId: txidA)),
        ]),
      );
    });

    test('\nWHEN pick file successfully and upload a file in encryption room.\n'
        'THEN upload file successfully.\n', () async {
      const txidA = 'txidA';

      final mockMatrixFile = List.generate(1, (_) => MockMatrixFile());

      when(room.client.generateUniqueTransactionId()).thenReturn(txidA);

      when(uploadManager.getUploadStateStream(txidA)).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(EncryptingFileState()),
          const Right(EncryptedFileState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          const Right(UploadFileSuccessState(eventId: txidA)),
        ]),
      );

      await uploadManager.uploadFilesWeb(room: room, files: mockMatrixFile);

      expect(room.client.generateUniqueTransactionId(), equals(txidA));

      expect(
        uploadManager.getUploadStateStream(txidA),
        emitsInOrder([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(EncryptingFileState()),
          const Right(EncryptedFileState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          const Right(UploadFileSuccessState(eventId: txidA)),
        ]),
      );
    });

    test('\nWHEN pick file successfully and upload a file.\n'
        'THEN upload file failed.\n', () async {
      const txidA = 'txidA';

      final mockMatrixFile = List.generate(1, (_) => MockMatrixFile());

      when(room.client.generateUniqueTransactionId()).thenReturn(txidA);

      when(uploadManager.getUploadStateStream(txidA)).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Left(UploadFileFailedState(exception: '')),
        ]),
      );

      await uploadManager.uploadFilesWeb(room: room, files: mockMatrixFile);

      expect(room.client.generateUniqueTransactionId(), equals(txidA));

      expect(
        uploadManager.getUploadStateStream(txidA),
        emitsInOrder([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Left(UploadFileFailedState(exception: '')),
        ]),
      );
    });

    test('\nWHEN pick files successfully and upload files.\n'
        'THEN upload files successfully.\n', () async {
      const txidA = 'txidA';
      const txidB = 'txidB';

      final listFiles = {txidA: MockMatrixFile(), txidB: MockMatrixFile()};

      when(room.client.generateUniqueTransactionId()).thenReturn(txidA);

      when(uploadManager.getUploadStateStream(txidA)).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          const Right(UploadFileSuccessState(eventId: txidA)),
        ]),
      );

      when(room.client.generateUniqueTransactionId()).thenReturn(txidB);

      when(uploadManager.getUploadStateStream(txidB)).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          const Right(UploadFileSuccessState(eventId: txidB)),
        ]),
      );

      await uploadManager.uploadFilesWeb(
        room: room,
        files: listFiles.values.toList(),
      );

      expect(
        uploadManager.getUploadStateStream(txidA),
        emitsInOrder([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          const Right(UploadFileSuccessState(eventId: txidA)),
        ]),
      );

      expect(
        uploadManager.getUploadStateStream(txidB),
        emitsInOrder([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          const Right(UploadFileSuccessState(eventId: txidB)),
        ]),
      );
    });

    test('\nWHEN pick files successfully and upload files.\n'
        'THEN upload files failed.\n', () async {
      const txidA = 'txidA';
      const txidB = 'txidB';

      final listFiles = {txidA: MockMatrixFile(), txidB: MockMatrixFile()};

      when(room.client.generateUniqueTransactionId()).thenReturn(txidA);

      when(uploadManager.getUploadStateStream(txidA)).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Left(UploadFileFailedState(exception: '')),
        ]),
      );

      when(room.client.generateUniqueTransactionId()).thenReturn(txidB);

      when(uploadManager.getUploadStateStream(txidB)).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Left(UploadFileFailedState(exception: '')),
        ]),
      );

      await uploadManager.uploadFilesWeb(
        room: room,
        files: listFiles.values.toList(),
      );

      expect(
        uploadManager.getUploadStateStream(txidA),
        emitsInOrder([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Left(UploadFileFailedState(exception: '')),
        ]),
      );

      expect(
        uploadManager.getUploadStateStream(txidB),
        emitsInOrder([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Left(UploadFileFailedState(exception: '')),
        ]),
      );
    });

    test('\nWHEN pick file successfully and upload files [A, B].\n'
        'AND cancel upload load file [A]'
        'THEN getUploadStateStream[A] SHOULD return UploadFileFailedState with CancelUploadException\n'
        'THEN upload file[B] successfully.\n', () async {
      const txidA = 'txidA';
      const txidB = 'txidB';

      final listFiles = {txidA: MockMatrixFile(), txidB: MockMatrixFile()};

      when(room.client.generateUniqueTransactionId()).thenReturn(txidA);

      when(uploadManager.getUploadStateStream(txidA)).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          Left(UploadFileFailedState(exception: CancelUploadException())),
        ]),
      );

      when(room.client.generateUniqueTransactionId()).thenReturn(txidB);

      when(uploadManager.getUploadStateStream(txidB)).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          const Right(UploadFileSuccessState(eventId: txidB)),
        ]),
      );

      await uploadManager.uploadFilesWeb(
        room: room,
        files: listFiles.values.toList(),
      );

      await Future.delayed(const Duration(seconds: 1), () {
        uploadManager.cancelUpload(Event.fromJson(creatEvent(txidA), room));
      });

      uploadManager.getUploadStateStream(txidA)?.listen((state) {
        state.fold((failure) {
          if (failure is UploadFileFailedState) {
            expect(failure.exception is CancelUploadException, true);
          }
        }, (success) => null);
      });

      expect(
        uploadManager.getUploadStateStream(txidB),
        emitsInOrder([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          const Right(UploadFileSuccessState(eventId: txidB)),
        ]),
      );
    });

    test(
      '\nWHEN pick file successfully and upload files [A, B].\n'
      'AND cancel upload load file [A] and [B]\n'
      'THEN getUploadStateStream[A] SHOULD return UploadFileFailedState with CancelUploadException\n'
      'THEN getUploadStateStream[B] SHOULD return UploadFileFailedState with CancelUploadException\n',
      () async {
        const txidA = 'txidA';
        const txidB = 'txidB';

        final listFiles = {txidA: MockMatrixFile(), txidB: MockMatrixFile()};

        when(room.client.generateUniqueTransactionId()).thenReturn(txidA);

        when(uploadManager.getUploadStateStream(txidA)).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            Left(UploadFileFailedState(exception: CancelUploadException())),
          ]),
        );

        when(room.client.generateUniqueTransactionId()).thenReturn(txidB);

        when(uploadManager.getUploadStateStream(txidB)).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            const Right(UploadingFileState(receive: 1, total: 1)),
            Left(UploadFileFailedState(exception: CancelUploadException())),
          ]),
        );

        await uploadManager.uploadFilesWeb(
          room: room,
          files: listFiles.values.toList(),
        );

        await Future.delayed(const Duration(seconds: 1), () {
          uploadManager.cancelUpload(Event.fromJson(creatEvent(txidA), room));
          uploadManager.cancelUpload(Event.fromJson(creatEvent(txidB), room));
        });

        uploadManager.getUploadStateStream(txidA)?.listen((state) {
          state.fold((failure) {
            if (failure is UploadFileFailedState) {
              expect(failure.exception is CancelUploadException, true);
            }
          }, (success) => null);
        });

        uploadManager.getUploadStateStream(txidB)?.listen((state) {
          state.fold((failure) {
            if (failure is UploadFileFailedState) {
              expect(failure.exception is CancelUploadException, true);
            }
          }, (success) => null);
        });
      },
    );

    test('\nWHEN pick file successfully and upload files [A, B].\n'
        'AND cancel upload load file [A] and [B]\n'
        'THEN getUploadStateStream[A] SHOULD return UploadFileFailedState with CancelUploadException\n'
        'THEN getUploadStateStream[B] SHOULD return UploadFileFailedState with CancelUploadException\n'
        'AND pick new file successfully and upload file [C, D]\n'
        'THEN upload file [C, D] successfully.\n', () async {
      const txidA = 'txidA';
      const txidB = 'txidB';

      final listFiles = {txidA: MockMatrixFile(), txidB: MockMatrixFile()};

      when(room.client.generateUniqueTransactionId()).thenReturn(txidA);

      when(uploadManager.getUploadStateStream(txidA)).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          Left(UploadFileFailedState(exception: CancelUploadException())),
        ]),
      );

      when(room.client.generateUniqueTransactionId()).thenReturn(txidB);

      when(uploadManager.getUploadStateStream(txidB)).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          Left(UploadFileFailedState(exception: CancelUploadException())),
        ]),
      );

      await uploadManager.uploadFilesWeb(
        room: room,
        files: listFiles.values.toList(),
      );

      verify(
        uploadManager.uploadFilesWeb(
          room: room,
          files: listFiles.values.toList(),
        ),
      ).called(1);

      await Future.delayed(const Duration(seconds: 1), () {
        uploadManager.cancelUpload(Event.fromJson(creatEvent(txidA), room));
        uploadManager.cancelUpload(Event.fromJson(creatEvent(txidB), room));
      });

      uploadManager.getUploadStateStream(txidA)?.listen((state) {
        state.fold((failure) {
          if (failure is UploadFileFailedState) {
            expect(failure.exception is CancelUploadException, true);
          }
        }, (success) => null);
      });

      uploadManager.getUploadStateStream(txidB)?.listen((state) {
        state.fold((failure) {
          if (failure is UploadFileFailedState) {
            expect(failure.exception is CancelUploadException, true);
          }
        }, (success) => null);
      });

      const txidC = 'txid_c';
      const txidD = 'txid_d';

      final newFiles = {txidC: MockMatrixFile(), txidD: MockMatrixFile()};

      when(room.client.generateUniqueTransactionId()).thenReturn(txidC);

      when(uploadManager.getUploadStateStream(txidC)).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          const Right(UploadFileSuccessState(eventId: txidC)),
        ]),
      );

      when(room.client.generateUniqueTransactionId()).thenReturn(txidD);

      when(uploadManager.getUploadStateStream(txidD)).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          const Right(UploadFileSuccessState(eventId: txidD)),
        ]),
      );

      await uploadManager.uploadFilesWeb(
        room: room,
        files: newFiles.values.toList(),
      );

      verify(
        uploadManager.uploadFilesWeb(
          room: room,
          files: newFiles.values.toList(),
        ),
      ).called(1);

      expect(
        uploadManager.getUploadStateStream(txidC),
        emitsInOrder([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          const Right(UploadFileSuccessState(eventId: txidC)),
        ]),
      );

      expect(
        uploadManager.getUploadStateStream(txidD),
        emitsInOrder([
          const Right(UploadFileInitial()),
          const Right(ConvertingStreamToBytesState()),
          const Right(ConvertedStreamToBytesState()),
          const Right(UploadingFileState(receive: 0, total: 1)),
          const Right(UploadingFileState(receive: 1, total: 1)),
          const Right(UploadFileSuccessState(eventId: txidD)),
        ]),
      );
    });

    test(
      '\nWHEN pick file successfully and upload files [A, B].\n'
      'AND cancel upload load file [A] and [B]\n'
      'THEN getUploadStateStream[A] SHOULD return UploadFileFailedState with CancelUploadException\n'
      'THEN getUploadStateStream[B] SHOULD return UploadFileFailedState with CancelUploadException\n'
      'AND pick new file successfully and upload file [C, D]\n'
      'AND cancel upload load file [C] and [D]\n'
      'THEN getUploadStateStream[C] SHOULD return UploadFileFailedState with CancelUploadException\n'
      'THEN getUploadStateStream[D] SHOULD return UploadFileFailedState with CancelUploadException\n',
      () async {
        const txidA = 'txidA';
        const txidB = 'txidB';

        final listFiles = {txidA: MockMatrixFile(), txidB: MockMatrixFile()};

        when(room.client.generateUniqueTransactionId()).thenReturn(txidA);

        when(uploadManager.getUploadStateStream(txidA)).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            Left(UploadFileFailedState(exception: CancelUploadException())),
          ]),
        );

        when(room.client.generateUniqueTransactionId()).thenReturn(txidB);

        when(uploadManager.getUploadStateStream(txidB)).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            const Right(UploadingFileState(receive: 1, total: 1)),
            Left(UploadFileFailedState(exception: CancelUploadException())),
          ]),
        );

        await uploadManager.uploadFilesWeb(
          room: room,
          files: listFiles.values.toList(),
        );

        verify(
          uploadManager.uploadFilesWeb(
            room: room,
            files: listFiles.values.toList(),
          ),
        ).called(1);

        await Future.delayed(const Duration(seconds: 1), () {
          uploadManager.cancelUpload(Event.fromJson(creatEvent(txidA), room));
          uploadManager.cancelUpload(Event.fromJson(creatEvent(txidB), room));
        });

        uploadManager.getUploadStateStream(txidA)?.listen((state) {
          state.fold((failure) {
            if (failure is UploadFileFailedState) {
              expect(failure.exception is CancelUploadException, true);
            }
          }, (success) => null);
        });

        uploadManager.getUploadStateStream(txidB)?.listen((state) {
          state.fold((failure) {
            if (failure is UploadFileFailedState) {
              expect(failure.exception is CancelUploadException, true);
            }
          }, (success) => null);
        });

        const txidC = 'txid_c';
        const txidD = 'txid_d';

        final newFiles = {txidC: MockMatrixFile(), txidD: MockMatrixFile()};

        when(room.client.generateUniqueTransactionId()).thenReturn(txidC);

        when(uploadManager.getUploadStateStream(txidC)).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            const Right(UploadingFileState(receive: 1, total: 1)),
            Left(UploadFileFailedState(exception: CancelUploadException())),
          ]),
        );

        when(room.client.generateUniqueTransactionId()).thenReturn(txidD);

        when(uploadManager.getUploadStateStream(txidD)).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            const Right(UploadingFileState(receive: 1, total: 1)),
            Left(UploadFileFailedState(exception: CancelUploadException())),
          ]),
        );

        await uploadManager.uploadFilesWeb(
          room: room,
          files: newFiles.values.toList(),
        );

        verify(
          uploadManager.uploadFilesWeb(
            room: room,
            files: newFiles.values.toList(),
          ),
        ).called(1);

        await Future.delayed(const Duration(seconds: 1), () {
          uploadManager.cancelUpload(Event.fromJson(creatEvent(txidC), room));
          uploadManager.cancelUpload(Event.fromJson(creatEvent(txidD), room));
        });

        uploadManager.getUploadStateStream(txidC)?.listen((state) {
          state.fold((failure) {
            if (failure is UploadFileFailedState) {
              expect(failure.exception is CancelUploadException, true);
            }
          }, (success) => null);
        });

        uploadManager.getUploadStateStream(txidD)?.listen((state) {
          state.fold((failure) {
            if (failure is UploadFileFailedState) {
              expect(failure.exception is CancelUploadException, true);
            }
          }, (success) => null);
        });
      },
    );

    test(
      '\nWHEN pick file successfully and upload files [A, B] in encryption room.\n'
      'AND cancel upload load file [A] and [B]\n'
      'THEN getUploadStateStream[A] SHOULD return UploadFileFailedState with CancelUploadException\n'
      'THEN getUploadStateStream[B] SHOULD return UploadFileFailedState with CancelUploadException\n'
      'AND pick new file successfully and upload file [C, D]\n'
      'THEN upload file [C, D] successfully.\n',
      () async {
        const txidA = 'txidA';
        const txidB = 'txidB';

        final listFiles = {txidA: MockMatrixFile(), txidB: MockMatrixFile()};

        when(room.client.generateUniqueTransactionId()).thenReturn(txidA);

        when(uploadManager.getUploadStateStream(txidA)).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(EncryptingFileState()),
            const Right(EncryptedFileState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            Left(UploadFileFailedState(exception: CancelUploadException())),
          ]),
        );

        when(room.client.generateUniqueTransactionId()).thenReturn(txidB);

        when(uploadManager.getUploadStateStream(txidB)).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(EncryptingFileState()),
            const Right(EncryptedFileState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            const Right(UploadingFileState(receive: 1, total: 1)),
            Left(UploadFileFailedState(exception: CancelUploadException())),
          ]),
        );

        await uploadManager.uploadFilesWeb(
          room: room,
          files: listFiles.values.toList(),
        );

        verify(
          uploadManager.uploadFilesWeb(
            room: room,
            files: listFiles.values.toList(),
          ),
        ).called(1);

        await Future.delayed(const Duration(seconds: 1), () {
          uploadManager.cancelUpload(Event.fromJson(creatEvent(txidA), room));
          uploadManager.cancelUpload(Event.fromJson(creatEvent(txidB), room));
        });

        uploadManager.getUploadStateStream(txidA)?.listen((state) {
          state.fold((failure) {
            if (failure is UploadFileFailedState) {
              expect(failure.exception is CancelUploadException, true);
            }
          }, (success) => null);
        });

        uploadManager.getUploadStateStream(txidB)?.listen((state) {
          state.fold((failure) {
            if (failure is UploadFileFailedState) {
              expect(failure.exception is CancelUploadException, true);
            }
          }, (success) => null);
        });

        const txidC = 'txid_c';
        const txidD = 'txid_d';

        final newFiles = {txidC: MockMatrixFile(), txidD: MockMatrixFile()};

        when(room.client.generateUniqueTransactionId()).thenReturn(txidC);

        when(uploadManager.getUploadStateStream(txidC)).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(EncryptingFileState()),
            const Right(EncryptedFileState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            const Right(UploadingFileState(receive: 1, total: 1)),
            const Right(UploadFileSuccessState(eventId: txidC)),
          ]),
        );

        when(room.client.generateUniqueTransactionId()).thenReturn(txidD);

        when(uploadManager.getUploadStateStream(txidD)).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(EncryptingFileState()),
            const Right(EncryptedFileState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            const Right(UploadingFileState(receive: 1, total: 1)),
            const Right(UploadFileSuccessState(eventId: txidD)),
          ]),
        );

        await uploadManager.uploadFilesWeb(
          room: room,
          files: newFiles.values.toList(),
        );

        verify(
          uploadManager.uploadFilesWeb(
            room: room,
            files: newFiles.values.toList(),
          ),
        ).called(1);

        expect(
          uploadManager.getUploadStateStream(txidC),
          emitsInOrder([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(EncryptingFileState()),
            const Right(EncryptedFileState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            const Right(UploadingFileState(receive: 1, total: 1)),
            const Right(UploadFileSuccessState(eventId: txidC)),
          ]),
        );

        expect(
          uploadManager.getUploadStateStream(txidD),
          emitsInOrder([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(EncryptingFileState()),
            const Right(EncryptedFileState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            const Right(UploadingFileState(receive: 1, total: 1)),
            const Right(UploadFileSuccessState(eventId: txidD)),
          ]),
        );
      },
    );

    test(
      '\nWHEN pick file successfully and upload files [A, B] in encryption room.\n'
      'AND cancel upload load file [A] and [B]\n'
      'THEN getUploadStateStream[A] SHOULD return UploadFileFailedState with CancelUploadException\n'
      'THEN getUploadStateStream[B] SHOULD return UploadFileFailedState with CancelUploadException\n'
      'AND pick new file successfully and upload file [C, D]\n'
      'AND cancel upload load file [C] and [D]\n'
      'THEN getUploadStateStream[C] SHOULD return UploadFileFailedState with CancelUploadException\n'
      'THEN getUploadStateStream[D] SHOULD return UploadFileFailedState with CancelUploadException\n',
      () async {
        const txidA = 'txidA';
        const txidB = 'txidB';

        final listFiles = {txidA: MockMatrixFile(), txidB: MockMatrixFile()};

        when(room.client.generateUniqueTransactionId()).thenReturn(txidA);

        when(uploadManager.getUploadStateStream(txidA)).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(EncryptingFileState()),
            const Right(EncryptedFileState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            Left(UploadFileFailedState(exception: CancelUploadException())),
          ]),
        );

        when(room.client.generateUniqueTransactionId()).thenReturn(txidB);

        when(uploadManager.getUploadStateStream(txidB)).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(EncryptingFileState()),
            const Right(EncryptedFileState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            const Right(UploadingFileState(receive: 1, total: 1)),
            Left(UploadFileFailedState(exception: CancelUploadException())),
          ]),
        );

        await uploadManager.uploadFilesWeb(
          room: room,
          files: listFiles.values.toList(),
        );

        verify(
          uploadManager.uploadFilesWeb(
            room: room,
            files: listFiles.values.toList(),
          ),
        ).called(1);

        await Future.delayed(const Duration(seconds: 1), () {
          uploadManager.cancelUpload(Event.fromJson(creatEvent(txidA), room));
          uploadManager.cancelUpload(Event.fromJson(creatEvent(txidB), room));
        });

        uploadManager.getUploadStateStream(txidA)?.listen((state) {
          state.fold((failure) {
            if (failure is UploadFileFailedState) {
              expect(failure.exception is CancelUploadException, true);
            }
          }, (success) => null);
        });

        uploadManager.getUploadStateStream(txidB)?.listen((state) {
          state.fold((failure) {
            if (failure is UploadFileFailedState) {
              expect(failure.exception is CancelUploadException, true);
            }
          }, (success) => null);
        });

        const txidC = 'txid_c';
        const txidD = 'txid_d';

        final newFiles = {txidC: MockMatrixFile(), txidD: MockMatrixFile()};

        when(room.client.generateUniqueTransactionId()).thenReturn(txidC);

        when(uploadManager.getUploadStateStream(txidC)).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(EncryptingFileState()),
            const Right(EncryptedFileState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            const Right(UploadingFileState(receive: 1, total: 1)),
            Left(UploadFileFailedState(exception: CancelUploadException())),
          ]),
        );

        when(room.client.generateUniqueTransactionId()).thenReturn(txidD);

        when(uploadManager.getUploadStateStream(txidD)).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(UploadFileInitial()),
            const Right(ConvertingStreamToBytesState()),
            const Right(ConvertedStreamToBytesState()),
            const Right(EncryptingFileState()),
            const Right(EncryptedFileState()),
            const Right(UploadingFileState(receive: 0, total: 1)),
            const Right(UploadingFileState(receive: 1, total: 1)),
            Left(UploadFileFailedState(exception: CancelUploadException())),
          ]),
        );

        await uploadManager.uploadFilesWeb(
          room: room,
          files: newFiles.values.toList(),
        );

        verify(
          uploadManager.uploadFilesWeb(
            room: room,
            files: newFiles.values.toList(),
          ),
        ).called(1);

        await Future.delayed(const Duration(seconds: 1), () {
          uploadManager.cancelUpload(Event.fromJson(creatEvent(txidC), room));
          uploadManager.cancelUpload(Event.fromJson(creatEvent(txidD), room));
        });

        uploadManager.getUploadStateStream(txidC)?.listen((state) {
          state.fold((failure) {
            if (failure is UploadFileFailedState) {
              expect(failure.exception is CancelUploadException, true);
            }
          }, (success) => null);
        });

        uploadManager.getUploadStateStream(txidD)?.listen((state) {
          state.fold((failure) {
            if (failure is UploadFileFailedState) {
              expect(failure.exception is CancelUploadException, true);
            }
          }, (success) => null);
        });
      },
    );
  });
}
