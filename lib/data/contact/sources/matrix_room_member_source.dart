import 'package:twake_chat/data/contact/datasources/matrix_room_member_datasource.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';

/// Matrix room members source: fills the unified store with the profiles the
/// SDK already holds locally (no per-user network call).
class MatrixRoomMemberSource implements ContactSource {
  const MatrixRoomMemberSource(this._datasource);

  final MatrixRoomMemberDatasource _datasource;

  @override
  ContactSourceKind get kind => ContactSourceKind.matrixRoomMember;

  @override
  Future<List<SourcedContact>> fetch() async {
    final members = await _datasource.fetchRoomMembers();

    return members
        .map(
          (member) => SourcedContact(
            matrixId: member.matrixId,
            value: ContactSourceValue(
              kind: kind,
              displayName: member.displayName,
              avatarUrl: member.avatarUrl,
            ),
          ),
        )
        .toList(growable: false);
  }
}
