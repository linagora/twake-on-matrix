import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/direct_chat/exceptions/create_direct_chat_exception.dart';
import 'package:twake_chat/domain/direct_chat/repositories/direct_chat_repository.dart';
import 'package:twake_chat/domain/usecase/room/unblock_user_interactor.dart';
import 'package:twake_chat/pages/chat_draft/draft_chat.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_controller.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/direct_chat_provider.dart';
import 'package:twake_chat/providers/upload_manager_provider.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';

class _StubContacts extends ContactsController {
  @override
  Stream<List<UnifiedContact>> build() => Stream.value(const []);
}

class _ActiveClient extends Notifier<Client?> {
  @override
  Client? build() => null;

  // ignore: use_setters_to_change_properties
  void set(Client? client) => state = client;
}

final _activeClient = NotifierProvider<_ActiveClient, Client?>(
  _ActiveClient.new,
);

class _FakeRoom extends Fake implements Room {
  _FakeRoom(this.id);

  @override
  final String id;

  @override
  String get name => 'room';

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      invocation.memberName == #sendTextEvent
      ? Future<String?>.value('event')
      : super.noSuchMethod(invocation);
}

class _FakeClient extends Fake implements Client {
  _FakeClient(this.byId);

  final Map<String, _FakeRoom> byId;

  @override
  Room? getRoomById(String id) => byId[id];
}

/// Each `createDirectChat` call waits on the next completer of [calls].
class _GatedRepository implements DirectChatRepository {
  final calls = <Completer<String>>[];

  @override
  Future<String> createDirectChat({
    required String contactMxId,
    required bool enableEncryption,
  }) {
    final call = Completer<String>();
    calls.add(call);
    return call.future;
  }

  @override
  bool isUsableDirectChat({
    required String roomId,
    required String contactMxId,
  }) => true;
}

class _FakeUnblock extends Fake implements UnblockUserInteractor {}

class _FakeUpload extends Fake implements UploadManager {}

class _TestDraft extends DraftChat {
  const _TestDraft({required super.contact});

  @override
  DraftChatController createState() => _TestController();
}

class _TestController extends DraftChatController {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _Harness {
  _Harness(this._tester) {
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        contactsControllerProvider.overrideWith(_StubContacts.new),
        activeMatrixClientProvider.overrideWith(
          (ref) => ref.watch(_activeClient),
        ),
        uploadManagerProvider.overrideWithValue(_FakeUpload()),
        directChatRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  final WidgetTester _tester;
  final repository = _GatedRepository();
  final visited = <String>[];
  late final ProviderContainer container;
  late final DraftChatController controller;

  Future<void> pump(Client client) async {
    getIt.registerSingleton<UnblockUserInteractor>(_FakeUnblock());
    container.read(_activeClient.notifier).set(client);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const _TestDraft(
            contact: PresentationContact(matrixId: '@bob:s'),
          ),
        ),
        GoRoute(
          path: '/rooms/:roomid',
          builder: (_, state) {
            visited.add(state.pathParameters['roomid']!);
            return const SizedBox();
          },
        ),
      ],
    );
    await _tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    controller = _tester.state<DraftChatController>(find.byType(_TestDraft));
  }

  /// Starts a send; the repository is then waiting on `repository.calls.last`.
  Future<void> send({OnRoomCreatedFailed onFailed}) async {
    await controller.sendText(onCreateRoomFailed: onFailed);
    await _tester.pump();
  }

  Future<void> settle() => _tester.pumpAndSettle();

  Future<void> unmount() => _tester.pumpWidget(const SizedBox());

  Completer<String> get lastCall => repository.calls.last;
}

Future<_Harness> _start(
  WidgetTester tester, {
  Map<String, _FakeRoom> rooms = const {},
}) async {
  final harness = _Harness(tester);
  addTearDown(getIt.reset);
  await harness.pump(_FakeClient(rooms));
  return harness;
}

void main() {
  group('a failed create request unblocks the screen', () {
    for (final failure in <Object>[
      const CreateDirectChatForbiddenException(),
      StateError('No active Matrix client'),
      ArgumentError('boom'),
    ]) {
      testWidgets('${failure.runtimeType}', (tester) async {
        final harness = await _start(tester);
        var failed = false;
        await harness.send(onFailed: () => failed = true);
        harness.controller.isSendingNotifier.value = true;

        harness.lastCall.completeError(failure);
        await harness.settle();

        expect(tester.takeException(), isNull);
        expect(failed, isTrue);
        expect(harness.controller.isSendingNotifier.value, isFalse);
        expect(harness.visited, isEmpty);
      });
    }
  });

  group('a request that is no longer current reports nothing', () {
    testWidgets('a newer request supersedes the older one', (tester) async {
      final harness = await _start(
        tester,
        rooms: {'!old:s': _FakeRoom('!old:s'), '!new:s': _FakeRoom('!new:s')},
      );
      var oldFailed = false;
      await harness.send(onFailed: () => oldFailed = true);
      final older = harness.lastCall;
      await harness.send();

      older.complete('!old:s');
      await harness.settle();
      expect(harness.visited, isEmpty);
      expect(oldFailed, isFalse);

      harness.lastCall.complete('!new:s');
      await harness.settle();
      expect(harness.visited, ['!new:s']);
    });

    testWidgets('a screen closed during the request is left alone', (
      tester,
    ) async {
      final harness = await _start(tester, rooms: {'!r:s': _FakeRoom('!r:s')});
      var failed = false;
      await harness.send(onFailed: () => failed = true);

      await harness.unmount();
      harness.lastCall.complete('!r:s');
      await harness.settle();

      expect(tester.takeException(), isNull);
      expect(failed, isFalse);
      expect(harness.visited, isEmpty);
    });

    testWidgets('an account switched during the request opens nothing', (
      tester,
    ) async {
      final harness = await _start(tester, rooms: {'!r:s': _FakeRoom('!r:s')});
      await harness.send();
      harness.controller.isSendingNotifier.value = true;

      harness.container.read(_activeClient.notifier).set(_FakeClient({}));
      harness.lastCall.complete('!r:s');
      await harness.settle();

      expect(harness.visited, isEmpty);
      expect(harness.controller.isSendingNotifier.value, isFalse);
    });
  });

  testWidgets('a created room is opened', (tester) async {
    final harness = await _start(tester, rooms: {'!r:s': _FakeRoom('!r:s')});
    await harness.send();

    harness.lastCall.complete('!r:s');
    await harness.settle();

    expect(harness.visited, ['!r:s']);
  });

  testWidgets('a room missing from the client reports the failure', (
    tester,
  ) async {
    final harness = await _start(tester);
    var failed = false;
    await harness.send(onFailed: () => failed = true);
    harness.controller.isSendingNotifier.value = true;

    harness.lastCall.complete('!gone:s');
    await harness.settle();

    expect(failed, isTrue);
    expect(harness.controller.isSendingNotifier.value, isFalse);
    expect(harness.visited, isEmpty);
  });
}
