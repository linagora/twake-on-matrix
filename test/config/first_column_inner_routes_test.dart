import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/first_column_inner_routes.dart';
import 'package:twake_chat/pages/new_group/new_group.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info.dart';
import 'package:twake_chat/pages/new_group/states/new_group_kind.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/widgets/twake_cupertino_page.dart';

void main() {
  const contact = PresentationContact(
    displayName: 'Bob',
    matrixId: '@bob:example.com',
  );

  Future<Widget> pageOf(
    WidgetTester tester,
    String name, {
    Object? arguments,
  }) async {
    await tester.pumpWidget(const SizedBox());
    final route =
        FirstColumnInnerRoutes.routes(name, arguments: arguments)
            as TwakeCupertinoPageRoute<dynamic>;
    return route.builder(tester.element(find.byType(SizedBox)));
  }

  group('FirstColumnInnerRoutes.routes', () {
    const infoRoutes = {
      'innernavigator/newgroupchatinfo': NewGroupKind.group,
      'innernavigator/newfeedinfo': NewGroupKind.feed,
      'innernavigator/newspaceinfo': NewGroupKind.space,
    };

    for (final MapEntry(key: name, value: kind) in infoRoutes.entries) {
      testWidgets('${name}_whenArguments_reachesTheInfoScreen', (tester) async {
        final page = await pageOf(
          tester,
          name,
          arguments: NewGroupInfoArguments({contact}, parentSpaceId: '!space'),
        );

        expect(page, isA<NewGroupChatInfo>());
        final info = page as NewGroupChatInfo;
        expect(info.contactsList, {contact});
        expect(info.parentSpaceId, '!space');
        expect(info.kind, kind);
      });
    }

    testWidgets('newgroup_whenParentIsGiven_reachesTheContactsScreen', (
      tester,
    ) async {
      final page = await pageOf(
        tester,
        'innernavigator/newgroup',
        arguments: '!space',
      );

      expect((page as NewGroup).parentSpaceId, '!space');
      expect(page.kind, NewGroupKind.group);
    });

    testWidgets('newspace_whenParentIsGiven_reachesTheContactsScreen', (
      tester,
    ) async {
      final page = await pageOf(
        tester,
        'innernavigator/newspace',
        arguments: '!space',
      );

      expect((page as NewGroup).parentSpaceId, '!space');
      expect(page.kind, NewGroupKind.space);
    });
  });
}
