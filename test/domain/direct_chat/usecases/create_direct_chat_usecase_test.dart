import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/direct_chat/exceptions/create_direct_chat_exception.dart';
import 'package:twake_chat/domain/direct_chat/repositories/direct_chat_repository.dart';
import 'package:twake_chat/domain/direct_chat/usecases/create_direct_chat_usecase.dart';

class _FakeDirectChatRepository implements DirectChatRepository {
  _FakeDirectChatRepository({this.usable = true});

  final bool usable;
  Object? createError;
  String? lastContact;

  @override
  Future<String> createDirectChat({required String contactMxId}) async {
    lastContact = contactMxId;
    final error = createError;
    if (error != null) throw error;
    return '!room:server';
  }

  @override
  bool isUsableDirectChat({
    required String roomId,
    required String contactMxId,
  }) => usable;

  @override
  String? findDirectChat({required String contactMxId}) => null;
}

void main() {
  const contact = '@alice:server';

  test('returns the room id of a usable direct chat', () async {
    final repository = _FakeDirectChatRepository();

    final roomId = await CreateDirectChatUseCase(
      repository,
    ).execute(contactMxId: contact);

    expect(roomId, '!room:server');
    expect(repository.lastContact, contact);
  });

  test('throws a room mismatch when the room is not usable', () async {
    final useCase = CreateDirectChatUseCase(
      _FakeDirectChatRepository(usable: false),
    );

    await expectLater(
      useCase.execute(contactMxId: contact),
      throwsA(
        isA<CreateDirectChatRoomMismatchException>()
            .having((e) => e.roomId, 'roomId', '!room:server')
            .having((e) => e.contactMxId, 'contactMxId', contact),
      ),
    );
  });

  test('lets the repository exceptions through', () async {
    final repository = _FakeDirectChatRepository()
      ..createError = const CreateDirectChatForbiddenException();

    await expectLater(
      CreateDirectChatUseCase(repository).execute(contactMxId: contact),
      throwsA(isA<CreateDirectChatForbiddenException>()),
    );
  });
}
