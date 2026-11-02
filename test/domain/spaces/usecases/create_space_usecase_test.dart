import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/exception/spaces/space_exception.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/domain/repository/new_group/new_group_repository.dart';
import 'package:twake_chat/domain/repository/spaces/space_repository.dart';
import 'package:twake_chat/domain/spaces/new_space.dart';
import 'package:twake_chat/domain/spaces/usecases/create_space_usecase.dart';

import 'create_space_usecase_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SpaceRepository>(),
  MockSpec<NewGroupRepository>(),
])
void main() {
  const space = NewSpace(name: 'Team');
  late MockSpaceRepository spaces;
  late MockNewGroupRepository groups;
  late CreateSpaceUseCase useCase;

  setUpAll(() {
    provideDummy<NewSpace>(space);
    provideDummy<CreateNewGroupChatRequest>(const CreateNewGroupChatRequest());
  });

  setUp(() {
    spaces = MockSpaceRepository();
    groups = MockNewGroupRepository();
    useCase = CreateSpaceUseCase(spaces, groups);
    when(spaces.createSpace(any)).thenAnswer((_) async => '!new');
  });

  group('CreateSpaceUseCase', () {
    test('always_addsASuggestedGeneralInTheSpace', () async {
      expect(await useCase.execute(space), '!new');

      verify(
        groups.createGroup(
          const CreateNewGroupChatRequest(
            groupName: 'General',
            enableEncryption: false,
            parentSpaceId: '!new',
            isSuggested: true,
          ),
        ),
      ).called(1);
    });

    test('whenGeneralFails_keepsTheSpace', () async {
      when(groups.createGroup(any)).thenThrow(Exception('down'));

      expect(await useCase.execute(space), '!new');
    });

    test('whenSpaceIsRefused_propagatesAndAddsNoGeneral', () async {
      when(spaces.createSpace(any)).thenThrow(const SpaceForbiddenException());

      await expectLater(
        useCase.execute(space),
        throwsA(isA<SpaceForbiddenException>()),
      );
      verifyNever(groups.createGroup(any));
    });
  });
}
